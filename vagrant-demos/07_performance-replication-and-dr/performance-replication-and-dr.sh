#!/usr/bin/env bash

# Link:
# https://github.com/hashicorp/vault-guides/tree/master/operations/local-replication

#VAULT DR Replication Setup
#https://learn.hashicorp.com/tutorials/vault/disaster-recovery?in=vault/day-one-consul

# Execute the following in three (four) separate terminals

vrd
vrd2
vrd3
# vrd4

# UI
# localhost:8200
# localhost:8202
# localhost:8204
# localhost:8206

# Next we'll create some users, policies and secrets on the primary cluster.
# This information will be validated on the replicated clusters as part of this exercise.

# login
vault login root
# enable user / pw
vault auth enable userpass
# create policy
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault-admin -

# create admin user with vault-admin policy
vault write auth/userpass/users/vault password=vault policies=vault-admin

# Create a normal user and write some data
vault login root
vault write auth/userpass/users/drtest password=drtest policies=user

echo '
path "supersecret/*" {
  capabilities = ["list", "read"]
}' | vault policy write user -
vault secrets enable -path=supersecret generic
vault kv put supersecret/drtest username=harold password=baines


--> #Für Demo Präsentation, CLI Befehle per Bash Script ausführen und Zwischenschritte aufzeigen in der GUI#

# Setup Performance Replication (show in UI for better understanding!)
vault login root
vault write -f sys/replication/performance/primary/enable
sleep 5
PRIMARY_PERF_TOKEN=$(vault write -format=json sys/replication/performance/primary/secondary-token id=vault2 \
  | jq --raw-output '.wrap_info .token' )
vault2 login root
vault2 write sys/replication/performance/secondary/enable token=${PRIMARY_PERF_TOKEN}

# Validation of performance replication on the primary cluster (vault) - can also check in UI
curl -s http://127.0.0.1:8200/v1/sys/replication/status | jq .

# Validation of performance replicaton on the secondary cluster (vault2) - can also check in UI
curl -s http://127.0.0.1:8202/v1/sys/replication/status | jq .

# At this point, you can validate that the user,
# policies and secrets have been replicated to the performance secondary cluster
# check in UI for better understanding
vault2 login root
vault2 kv get supersecret/drtest

# Setup DR replication (vault -> vault3) - (show in UI for better understanding!)
vault login root
vault write -f /sys/replication/dr/primary/enable
sleep 5
PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id="vault3" | jq --raw-output '.wrap_info .token' )
vault3 login root
vault3 write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

# Validation of disaster replication on the primary using the CLI (vault),
# and jq just to make the output a bit more legible.
# Can also check in UI
vault read -format=json sys/replication/status | jq .

# Validation of disaster recovery replication on the DR secondary using API (vault3)
# Can also check in UI
curl -s http://127.0.0.1:8204/v1/sys/replication/status | jq .


#######################################################################
##
## It is additionally possible to setup DR for the performance replica.
## Redo the DR step from DR with the performance replica as DR primary
## and a new cluster (machine) as DR secondary.
##
#######################################################################

# To promote a DR secondary to a primary cluster, a DR operation token must be generated.
# First we will check to see if the 'generate operation token' process has not been initiated.
# These operations are completed on the DR secondary (vault3).
curl -s http://127.0.0.1:8204/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq .


# We will generate a one time password (otp)
DR_OTP=$(vault3 operator generate-root -dr-token -generate-otp)

# We will initiate the DR token generation process by creating a nonce
NONCE=$(vault3 operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')

# Validate the process has started
curl -s http://127.0.0.1:8204/v1/sys/replication/dr/secondary/generate-operation-token/attempt | jq .

# The DR Operation token requires the unseal key from the DR primary (vault)
# as well as the nonce created in the prior execution.

# Initiate DR token generation, provide unseal keys (1 unseal key in our example)
PRIMARY_UNSEAL_KEY="YOUR_UNSEAL_KEY_GOES_HERE"

ENCODED_TOKEN=$(vault3 operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )

# Next the DR operation token can be decoded via the following command
DR_OPERATION_TOKEN=$(vault3 operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})

# Failover Test - You can do in UI for better understanding

# Login with a normal user to obtain an authentication token for validation purposes
vault login -method=userpass username=drtest password=drtest

# Confirm this user can read a secret
vault read supersecret/drtest

# To perform the failover test, we can either disable replication on the primary, or demote the primary to a secondary.

# OPTION 1 - Disable replication

vault login root
vault write -f /sys/replication/dr/primary/disable
vault write -f /sys/replication/performance/primary/disable

# Now check replication status on the primary

curl -s http://127.0.0.1:8200/v1/sys/replication/status | jq .

# Check the DR secondary as well

curl -s http://127.0.0.1:8204/v1/sys/replication/status | jq .

# OPTION 2 - Demotion of replication role Demote primary to secondary

vault write -f /sys/replication/performance/primary/demote
vault write -f /sys/replication/dr/primary/demote


# Validate that secrets can be accessed on the performance secondary

vault2 login -method=userpass username=drtest password=drtest
vault2 read supersecret/drtest

# Next, promote DR secondary to primary, with the DR operation token
# (remember that the variables we've used are ephemeral and only good within a single shell session)

vault3 write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}

# Check status

vault3 read -format=json sys/replication/status | jq .

# FAILBACK for the first Vault cluster

# Enable vault as DR secondary to vault3 This will ensure if there are changes
# to the replication set (data; that is policies/secrets and so forth),
# that the changes are propagated back to the original primary (vault)

# After DR promotion vault3 is already configured as DR primary as it inherited that role from vault
# Show in UI

vault3 login root
vault3 write -f /sys/replication/dr/primary/enable
PRIMARY_DR_TOKEN=$(vault3 write -format=json /sys/replication/dr/primary/secondary-token id=vault | jq --raw-output '.wrap_info .token' )
vault login root
vault write /sys/replication/dr/secondary/enable token=${PRIMARY_DR_TOKEN}

# Promote original Vault instance back to disaster recovery primary
# UI

DR_OTP=$(vault operator generate-root -dr-token -generate-otp)
NONCE=$(vault operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
ENCODED_TOKEN=$(vault operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
DR_OPERATION_TOKEN=$(vault operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
vault write -f /sys/replication/dr/secondary/promote dr_operation_token=${DR_OPERATION_TOKEN}

# Demote vault 3 to secondary to return to original setup as DR secondary
# UI

vault3 write -f /sys/replication/performance/primary/demote
vault3 write -f /sys/replication/dr/primary/demote

# Now we will update the primary address for the DR secondary cluster (vault3)
# UI

PRIMARY_DR_TOKEN=$(vault write -format=json /sys/replication/dr/primary/secondary-token id=vault3 | jq --raw-output '.wrap_info .token' )
DR_OTP=$(vault3 operator generate-root -dr-token -generate-otp)
NONCE=$(vault3 operator generate-root -dr-token -init -otp=${DR_OTP} | grep -i nonce | awk '{print $2}')
ENCODED_TOKEN=$(vault3 operator generate-root -dr-token -nonce=${NONCE} ${PRIMARY_UNSEAL_KEY} | grep -i encoded | awk '{print $3}'  )
DR_OPERATION_TOKEN=$(vault3 operator generate-root -dr-token -otp=${DR_OTP} -decode=${ENCODED_TOKEN})
vault3 write sys/replication/dr/secondary/update-primary dr_operation_token=${DR_OPERATION_TOKEN} token=${PRIMARY_DR_TOKEN}

# Check status on all 3 (4)

vault read -format=json sys/replication/status | jq .
vault2 read -format=json sys/replication/status | jq .
vault3 read -format=json sys/replication/status | jq .
# vault4 read -format=json sys/replication/status | jq .