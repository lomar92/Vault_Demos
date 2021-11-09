#!/usr/bin/env bash

# Mount generic backends and write some secrets
vault secrets enable  -path=supersecret -version=2 kv

# Single KVs
vault kv  put  supersecret/admin my_password=hope_no_one_finds_out

# Multiple KVs
#vault kv  put  supersecret/admin admin_user=root admin_password=P@55w3rd

# Show KVs
#vault kv get  supersecret/admin

#Show specific KV
#vault kv get -field=admin_user supersecret/admin

#Create another version
vault kv  put  supersecret/admin my_password=Im_sure_no_one_finds_out
#Create yet another version :)
vault kv  put  supersecret/admin my_password=Okay_its_safe!

#Username does not exists
#vault kv get  supersecret/admin

#Use patch to include also admin_user instead of creating another version
#vault kv patch  supersecret/admin admin_user=root

#Show KVs - different versions
vault kv get  supersecret/admin
vault kv get  -version=1 supersecret/admin
vault kv get  -version=3 supersecret/admin
vault kv get  -version=2 supersecret/admin

#Specify Number of versions to keep!
#vault write secret/config max_versions=<integer>
#vault read secret/config


#Configure Secret at Path /supersecret/admin
#vault kv metadata put -max-versions=4 supersecret/admin 
#vault kv metadata get supersecret/admin

#Create more number of versions


#End
# ----------------------------------------------------------------

#Rollback to previous or specific version
#vault kv rollback  -version=1 supersecret/admin
#vault kv get  supersecret/admin

#Rollback to version 2
#vault kv rollback  -version=3 supersecret/admin
#vault kv get  supersecret/admin
# Demo End
# ----------------------------------------------------------------
#Argument for namespace: -namespace=DBAs




Another Example kv2
#customer secrets - confidential customer data

#Enable kv2 secret engine
#vault kv put secret/customer/acme @acme.json

# What happens when you execute the following command???
vault kv put secret/customer/acme \
# contact_email="jennifer@acme.com"

#Check
vault kv get secret/customer/acme 

#Oh No!
--> rollback to version1
vault kv rollback -version=1 secret/customer/acme

#Updating Secrets
vault kv patch secret/customer/acme \
 contact_email="jennifer@acme.com"

#Adding Secrets
vaul kv patch secret/customer/acme phone_number=08945781354

