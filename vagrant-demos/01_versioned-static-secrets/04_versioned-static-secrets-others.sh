#!/usr/bin/env bash

#List secrets / Keys under supersecret
vault kv list supersecret

curl --header "X-Vault-Token: root" --request POST \
--data '{"data": {"apikey": "my-api-key"} }' \
$VAULT_ADDR/v1/secret/data/apikey/google | jq

--------
# Normal servers have version 1 of KV mounted by default, so will need these
# paths:
echo '
path "sys/mounts" {
  capabilities = ["list","read"]
}
path "secret/*" {
  capabilities = ["create"]
}
path "secret/foo" {
  capabilities = ["read"]
}
# Dev servers have version 2 of KV mounted by default, so will need these
# paths:
path "supersecret/*" {
  capabilities = ["list","create","read"]
}
path "supersecret/data/*" {
  capabilities = ["list","create","read"]
}
path "supersecret/data/admin" {
  capabilities = ["list"]
} ' | vault policy write user -


--------

# Disable generic backends
vault secrets disable supersecret

-------------------

##PATH-HELP
vault path-help secret

vault path-help sys

vault path-help sys/auth