#!/usr/bin/env bash


# Create a Secret
vault kv put secret/mysecret value=hush

# Create a Wrapped Secret Response

vault kv get secret/mysecret

vault kv get -wrap-ttl="20s" secret/mysecret

# Instead of 20s, give it 2min 
vault kv get -wrap-ttl="2m" secret/mysecret

#When you unwrap, the secret is given
VAULT_TOKEN=<Wrapping Token> vault unwrap


# Same with the API, 5mins
curl -H "X-Vault-Token: ${VAULT_TOKEN}" -H "X-Vault-Wrap-TTL: 5m" "http://127.0.0.1:8200/v1/secret/data/mysecret"

#wrapping_token:                 s.QMQyMCAB0cyxOTNA9kFYuKB9
#wrapping_accessor:               xENzgSgSYSOwWfS1htBa5JRT

#Lookup Wrapped Token
vault token lookup <wrapping_token>

OR

curl -X POST -H "X-Vault-Token:$VAULT_TOKEN" -d '{"token":"wrapping_token"}' $VAULT_ADDR/v1/sys/wrapping/lookup

#curl -H "X-Vault-Token: $1" http://127.0.0.1:8200/v1/sys/wrapping/lookup


----
#Try to read without policy

vault token create -policy=default
vault login <token>

unset VAULT_TOKEN
vault read secret/mysecret

-----

#UPWRAP TOKEN

vault unwrap 0ad7862c-0a10-0732-23fd-63f59899d889
OR

VAULT_TOKEN=<Wrapping Token> vault unwrap

curl -X POST -H "X-Vault-Token:$VAULT_TOKEN" -d '{"token":"5259ae36-f228-b873-6ac6-f6618d5db746"}' $VAULT_ADDR/v1/sys/wrapping/unwrap

--------------------------

#Another method is to not wrap the secret but wrap a token to get to the secret

# First create the apps-policy
---
echo '
path "auth/token/*" {
  capabilities = [ "create", "read", "update", "delete", "sudo" ]
}

# Write ACL policies
path "sys/policy/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

}
path "secret/*" {
  capabilities = [  "list" ]
}

path "secret/data/mysecret" {
  capabilities = [  "read" ]
}' | vault policy write apps-policy -

----

#Demo using UI


# Put a secret (if not existing)
vault kv put secret/mysecret value=hush
# Create Token with the apps-policy policy
vault token create -policy=apps-policy -ttl=10m -wrap-ttl=5m
# Do the same but with an explicit use of 3 times
#vault token create -policy=apps-policy -ttl=10m -num_uses=3 -wrap-ttl=5m
# Create token with default policy
vault token create -policy=default
# Login with the default policy token
vault login <token>
# Unwrap the previous wrapping token that was created with apps_policy
# to get access to the apps-policy Token
VAULT_TOKEN=<Wrapping Token> vault unwrap
# Login with the unwrapped Token
vault login <TOKEN>
# Read secrets
VAULT_TOKEN=<unwrapped token>  vault kv get secret/mysecret

---------------------------------------------------------------------------

# To REVOKE USER
vault lease revoke -prefix auth/userpass/login/demo

#TO DELETE USER
vault delete auth/userpass/users/demo

# Create user
vault write auth/userpass/users/demo password=test