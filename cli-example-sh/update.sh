#!/bin/bash
export YC_IMAGE_FAMILY="ubuntu-2004-lts"
export TUTORIAL_SSH_KEY=$(cat ~/.ssh/tutorial_id_rsa.pub)
if [ $# -eq 0 ]; then export YC_PREFIX=cli; else export YC_PREFIX=$1; fi

export YC_VPC_NETWORK=$(yc vpc network get --name $YC_PREFIX-network --format json | jq .id | tr -d \")
export YC_SERVICE_ACCOUNT=$(yc iam service-account get --name $YC_PREFIX-editor-sa  --format json | jq .id | tr -d \")
export YC_IMAGE=$(yc compute image get-latest-from-family $YC_IMAGE_FAMILY --folder-id standard-images --format json  | jq .id | tr -d \")

export YC_VPC_SUBNET_A=$(yc vpc subnet get --name $YC_PREFIX-subnet-a --format json | jq .id | tr -d \")
export YC_VPC_SUBNET_B=$(yc vpc subnet get --name $YC_PREFIX-subnet-b --format json | jq .id | tr -d \")
export YC_VPC_SUBNET_C=$(yc vpc subnet get --name $YC_PREFIX-subnet-c --format json | jq .id | tr -d \")

echo 'Creating specification yaml file from template >> ig-spec.yaml'
envsubst '${YC_PREFIX} ${YC_SERVICE_ACCOUNT} ${YC_VPC_NETWORK} ${YC_IMAGE} ${TUTORIAL_SSH_KEY} ${YC_VPC_SUBNET_A} ${YC_VPC_SUBNET_B} ${YC_VPC_SUBNET_C}' < ig-spec.tpl.yaml > ig-spec.yaml

echo "Updating instance group $YC_PREFIX-instance-group"
yc compute instance-group update \
  --name $YC_PREFIX-instance-group \
  --file ig-spec.yaml 

yc compute instance-group list-instances --name $YC_PREFIX-instance-group