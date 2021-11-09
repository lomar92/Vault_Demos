#!/usr/bin/env bash

# How to login with root:
# mysql -u root -p'R00tPassword'

# Create new namespace
vault namespace create DBA

# Set Namespace as ENV Variable
export VAULT_NAMESPACE=DBA

# Grant access to a privileged user that Vault can use
mysql -u root -p'R00tPassword' << EOF
CREATE USER 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword';
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' WITH GRANT OPTION;
EOF

# Enable the databases secrets engine
vault secrets enable database
#vault secrets enable database -path=mysql_db

# Configure MySQL secrets for the databases secrets engine
vault write database/config/mysql \
    plugin_name=mysql-database-plugin \
    connection_url="vaultadmin:vaultadminpassword@tcp(127.0.0.1:3306)/" \
    allowed_roles="readonly"

# Same in one line
#vault write database/config/mysql plugin_name=mysql-database-plugin connection_url="vaultadmin:vaultadminpassword@tcp(127.0.0.1:3306)/" allowed_roles="readonly"

# Create a role so applications can access credentials
vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1m"

# max_ttl="24h"

# Request credentials by reading from the role
vault read -namespace=DBA database/creds/readonly
sleep 5
vault read -namespace=DBA database/creds/readonly
sleep 5
vault read -namespace=DBA database/creds/readonly
sleep 5
vault read -namespace=DBA database/creds/readonly
sleep 5
vault read -namespace=DBA database/creds/readonly

# Unset NameSpace ENV Variable:
unset VAULT_NAMESPACE

# Check for users
#mysql -u root -p'R00tPassword' -e "select user from mysql.user;"

# Watch Users getting added / deleted
#watch -n 5 "mysql -u root -p'R00tPassword' -e \"select user from mysql.user;\""

#List a lease
#vault list sys/leases/lookup/database/creds/readonly/

#Details on a lease
#vault write sys/leases/lookup lease_id=database/creds/readonly/<Key>

# Revoke a lease
#vault lease revoke <lease>

# Revoke all leases
#vault lease revoke -prefix=true database/creds/readonly