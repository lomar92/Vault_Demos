#!/usr/bin/env bash

# Delete current /secret kv store
vault secrets disable secret

# Enable kv
vault secrets enable -version=1 -path=secret kv

# Save Secret in kv
vault kv put secret/foo mypwd=supersafe

# Enable user/pass auth method
vault auth enable userpass

# Configure TOTP MFA
vault write sys/mfa/method/totp/my_totp \
    issuer=Vault \
    period=60 \
    key_size=30 \
    algorithm=SHA256 \
    digits=6

# Create Policy for the Secret to just access via MFA
vault policy write totp-policy -<<EOF
path "secret/foo" {
  capabilities = ["read"]
  mfa_methods  = ["my_totp"]
}
EOF

# MFA works only for tokens that have identity information on them.
# Tokens created by logging in using auth methods will have the associated identity information.
# Create a user in the userpass auth method
vault write auth/userpass/users/testuser \
    password=testpassword \
    policies=totp-policy

# Create a login token
# vault write auth/userpass/login/testuser \
#    password=testpassword

# Create and save login token
TOKEN=$(vault write auth/userpass/login/testuser password=testpassword | grep token | head -1 | xargs | cut -d" " -f2)

# Fetch entity ID from token
# vault token lookup $TOKEN
ENTITY_ID=$(vault token lookup $TOKEN | grep entity_id | xargs | cut -d" " -f2)

# Generate TOTP method attached to the entity - decode the base64 to image and scan code with mobile device (Okta verify, Google authenticator, etc.) 
vault write sys/mfa/method/totp/my_totp/admin-generate entity_id=$ENTITY_ID

# Logging into vault with testuser token
vault login $TOKEN

# Read the secret, specifying the mfa flag
# vault read -mfa my_totp:<put_six_digit_number_from_device_here!> secret/foo