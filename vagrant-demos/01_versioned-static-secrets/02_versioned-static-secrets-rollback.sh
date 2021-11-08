#!/usr/bin/env bash

#Rollback to previous or specific version
vault kv rollback  -version=1 supersecret/admin
vault kv get  supersecret/admin