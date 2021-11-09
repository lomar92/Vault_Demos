#!/usr/bin/env bash

#Set URL and version
export VAULT_URL="https://releases.hashicorp.com/vault" VAULT_VERSION="1.8.4+ent"

export VAULT_LICENSE_PATH=license.hclic

#Download Vault
curl \
    --silent \
    --remote-name \
   "${VAULT_URL}/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"

#Update
sudo apt-get update -y
#Unzip
sudo apt-get install -y unzip
unzip vault_${VAULT_VERSION}_linux_amd64.zip
#Install jq
sudo apt install -y jq
#Install MySQL
sudo apt install -y mysql-server
#Setup root password for mysql
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'R00tPassword';"
#Owner of Binary
sudo chown root:root vault
#Set system path
sudo mv vault /usr/local/bin/
#Set profile
cat ./profile.txt >> .bashrc
#Set permissions
chmod 700 -R ./0*
#Remove .zip
rm -rf vault_${VAULT_VERSION}_linux_amd64.zip
#Install Python3-pip
sudo apt install python3-pip -y
#Install HVAC FLASK
pip3 install mysql-connector-python hvac Flask
#Install Docker 
sudo apt install docker.io -y

#Stop mysql Service if you want to release Port 3306 for mysql running in docker
#sudo netstat -nlpt |grep 3306
#sudo service mysql stop

