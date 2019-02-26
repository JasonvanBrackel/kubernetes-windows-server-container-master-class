#!/bin/bash
#Provision Nodes in Azure
terraform apply -auto-approve
terraform apply # Seems to be an issue with the azure provider where publicips aren't there.  Will research later.
terraform output -json > output.json

# Grab ssh variables
admin=$(cat output.json | jq '.admin.value' | sed 's/\"//g')
private_key_path=$(cat output.json | jq '.administrator_ssh_private.value' | sed 's/\"//g')
private_key_path2=$(echo $private_key_path | sed 's/\//\\\//g')
resource_group_name=$(cat output.json | jq '.resource_group.value' | sed 's/\"//g')