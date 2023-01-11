#!/bin/bash
export YC_IMAGE_FAMILY="ubuntu-2004-lts"
if [ $# -eq 0 ]; then export YC_PREFIX=cli; else export YC_PREFIX=$1; fi

export YC_VPC_NETWORK_ID=$(yc vpc network get --name $YC_PREFIX-network --format json | jq .id | tr -d \")
export YC_SERVICE_ACCOUNT=$(yc iam service-account get --name $YC_PREFIX-editor-sa  --format json | jq .id | tr -d \")
export YC_IMAGE_ID=$(yc compute image get-latest-from-family $YC_IMAGE_FAMILY --folder-id standard-images --format json  | jq .id | tr -d \")

echo 'Creating specification yaml file from template >> ig-spec.yaml'
envsubst '${YC_PREFIX} ${YC_SERVICE_ACCOUNT} ${YC_VPC_NETWORK_ID} ${YC_IMAGE_ID}' < ig-spec.yaml.tpl > ig-spec.yaml

echo "Updating instance group $YC_PREFIX-instance-group"
yc compute instance-group update \
  --name $YC_PREFIX-instance-group \
  --file ig-spec.yaml 

yc compute instance-group list-instances --name $YC_PREFIX-instance-group