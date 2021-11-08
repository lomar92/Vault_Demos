#!/usr/bin/env bash

# Mount generic backends and write some secrets
vault kv put secret/demo username=demo password=supersecret

vault secrets enable -path=supersecret kv
vault kv put supersecret/admin admin_user=root admin_password=P@55w3rd
vault secrets enable -path=verysecret kv
vault kv put verysecret/sensitive key=value password=35616164316lasfdasfasdfasdfasdfasf

# Mount userpass backend
vault auth enable userpass

# Create user
vault write auth/userpass/users/demo password=test policies=user

# Auth using userpass on CLI or in UI
vault login -method=userpass username=demo

# demo has limited access

# Log back in as 'root'
vault login $VAULT_TOKEN

# Create the 'user' policy

# Create a policy to govern userpass and give users with that policy
# access to secret and supersecret but not to verysecret
echo '
path "sys/mounts" {
  capabilities = ["list","read"]
}
path "secret/*" {
  capabilities = ["list", "read"]
}
path "secret/demo" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "supersecret/*" {
  capabilities = ["list", "read"]
}' | vault policy write user -

# Log out as root and back in as 'demo'
  - demo does not have access to 'verysecret' path.
  - demo has read access to 'supersecret'
  - demo has read / write access to 'secret/demo' and read to all other under 'secret'


OR

# Just access to supersecret
echo '
path "sys/mounts" {
  capabilities = ["list","read"]
}
path "supersecret/*" {
  capabilities = ["list", "read"]
}' | vault policy write user -


# Log out as root and back in as 'demo'
  - demo does not have access to 'verysecret' & 'secret' path.
  - demo has read access to 'supersecret'


# Demo End
# ---------------------------------------------------------------------------



vault policy write my-policy my-policy.hcl

vault policy list
-----

unset VAULT_TOKEN

vault login -method=userpass username=demo

vault read -format json secret/demo
vault read -format json supersecret/admin
vault read -format json verysecret/sensitive

----
 export VAULT_TOKEN=${TOKEN}
vault login $VAULT_TOKEN

# To REVOKE USER
vault lease revoke -prefix auth/userpass/login/demo

#TO DELETE USER
vault delete auth/userpass/users/demo



----

# Disable generic backends
vault delete secret/demo

vault secrets disable supersecret

vault secrets disable verysecret