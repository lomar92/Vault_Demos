alias vrd="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 -dev-ha -dev-transactional"
alias vrd2="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8202 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8202 -dev-ha -dev-transactional"
alias vrd3="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8204 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8204 -dev-ha -dev-transactional"
alias vrd4="VAULT_UI=true VAULT_REDIRECT_ADDR=http://127.0.0.1:8206 vault server -log-level=trace -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8206 -dev-ha -dev-transactional"


vault2 () {
  VAULT_ADDR=http://127.0.0.1:8202 vault $@
}

vault3 () {
  VAULT_ADDR=http://127.0.0.1:8204 vault $@
}

vault4 () {
  VAULT_ADDR=http://127.0.0.1:8206 vault $@
}

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_SKIP_VERIFY=true

export VAULT_LICENSE_PATH=license.hclic

