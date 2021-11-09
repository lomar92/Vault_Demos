#!/usr/bin/env bash

# Put a secret (if not existing)
vault kv put secret/mysecret value=hush

#First create (or change) a policy
echo '
path "auth/token/*" {
  capabilities = [ "create", "read", "update", "delete", "sudo" ]
}

# Manage secret/dev secret engine - for Verification test
path "secret/dev" {
  capabilities = [ "read" ]
}

# Manage secret/dev secret engine - for Verification test
path "secret/mysecret" {
  capabilities = [ "read" ]
}

path "auth/approle/role/application/role-id" {
  capabilities = ["read"]
}

path "auth/approle/role/application/secret-id" {
  capabilities = ["update"]
}

path "auth/approle/login" {
  capabilities = [ "create", "read"]
}

path "application/" {
  capabilities = ["list"]
}

path "application/*" {
  capabilities = ["list", "read"]
}' | vault policy write apps-policy -

# Enable the approle secrets engine
vault auth enable approle

#vault auth disable approle

#vault write auth/approle/role/jenkins policies="jenkins" secret_id_num_uses=1 secret_id_ttl=90

# Create a secret ID
vault write auth/approle/role/myapp policies="apps-policy" secret_id_num_uses=1 secret_id_ttl=5m

#curl -X POST -H "X-Vault-Token: $1" -d '{"policies": "'"$2"'"}' "http://127.0.0.1:8200/v1/auth/approle/role/$2"

# Check myapp
vault read auth/approle/role/myapp

#Get Role ID
vault read auth/approle/role/myapp/role-id

--------------
# via API
export APPROLE="myapp"
ROLE_ID=$(curl -H "X-Vault-Token: ${TOKEN}" "http://127.0.0.1:8200/v1/auth/approle/role/${APPROLE}/role-id" | jq -r '.data.role_id')
echo ${ROLE_ID}
--------------

# Get Secret
vault write -f auth/approle/role/myapp/secret-id

--------------
# via API
SECRET_ID=$(curl -X POST -H "X-Vault-Token:${TOKEN}" "http://127.0.0.1:8200/v1/auth/approle/role/${APPROLE}/secret-id" | jq -r '.data.secret_id')
echo ${SECRET_ID}
--------------

# Get token with Role_ID and Secret_ID
vault write auth/approle/login role_id=${ROLE_ID} \
  secret_id=${SECRET_ID}

  --------------
# via API
APP_ROLE_TOKEN=$(curl -X POST -d '{"role_id": "'"$ROLE_ID"'", "secret_id": "'"$SECRET_ID"'"}' http://127.0.0.1:8200/v1/auth/approle/login | jq -r '.auth.client_token')

--------------

# Use token to read secret
VAULT_TOKEN=${APP_ROLE_TOKEN} vault kv get secret/mysecret

