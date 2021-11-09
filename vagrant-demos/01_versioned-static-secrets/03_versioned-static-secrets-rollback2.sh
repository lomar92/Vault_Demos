#!/usr/bin/env bash

#Rollback to version 3
vault kv rollback  -version=3 supersecret/admin
vault kv get  supersecret/admin