#!/bin/bash
export YC_IMAGE_FAMILY="ubuntu-1804-lts"
if [ $# -eq 0 ]; then export YC_PREFIX=cli; else export YC_PREFIX=$1; fi
 
echo 'Creating network'
export YC_VPC_NETWORK_ID=$(yc vpc network create --name $YC_PREFIX-network --description 'created with shell script' --format json | jq .id | tr -d \")
yc vpc network get --id $YC_VPC_NETWORK_ID --format json

echo 'Creating subnet in zone ru-central1-a'
export YC_VPC_SUBNET_A=$(yc vpc subnet create --name $YC_PREFIX-subnet-a --zone "ru-central1-a" --range "192.168.10.0/24" --network-id $YC_VPC_NETWORK_ID   --format json | jq .id | tr -d \")
yc vpc subnet get --id $YC_VPC_SUBNET_A --format json

echo 'Creating subnet in zone ru-central1-b'
export YC_VPC_SUBNET_B=$(yc vpc subnet create --name $YC_PREFIX-subnet-b --zone "ru-central1-b" --range "192.168.11.0/24" --network-id $YC_VPC_NETWORK_ID   --format json | jq .id | tr -d \")
yc vpc subnet get --id $YC_VPC_SUBNET_B --format json

echo 'Creating subnet in zone ru-central1-c'
export YC_VPC_SUBNET_C=$(yc vpc subnet create --name $YC_PREFIX-subnet-c --zone "ru-central1-c" --range "192.168.12.0/24" --network-id $YC_VPC_NETWORK_ID   --format json | jq .id | tr -d \")
yc vpc subnet get --id $YC_VPC_SUBNET_C --format json

echo 'Creating a service account cli-editor-sa to work with instance groups'
export YC_SERVICE_ACCOUNT=$(yc iam service-account create --name $YC_PREFIX-editor-sa  --format json | jq .id | tr -d \")
echo 'Binding editor role to the service account'
yc resource-manager folder add-access-binding --id $(yc config get folder-id) --service-account-id $YC_SERVICE_ACCOUNT --role editor
echo 'Resolving image id'
export YC_IMAGE_ID=$(yc compute image get-latest-from-family $YC_IMAGE_FAMILY --folder-id standard-images --format json  | jq .id | tr -d \")
echo 'Creating specification yaml file from template >> ig-spec.yaml'
envsubst '${YC_PREFIX} ${YC_SERVICE_ACCOUNT} ${YC_VPC_NETWORK_ID} ${YC_IMAGE_ID}' < ig-spec.yaml.tpl > ig-spec.yaml
echo 'Creating instance group from ig-spec.yaml'
export YC_INSTANCE_GROUP=$(yc compute instance-group create --file ig-spec.yaml --format json | jq .id | tr -d \")
yc compute instance-group list-instances $YC_INSTANCE_GROUP
 
echo 'Creating a network load balancer'
yc load-balancer network-load-balancer create \
  --region-id ru-central1 \
  --name $YC_PREFIX-network-load-balancer \
  --listener name=$YC_PREFIX-nlb-listener,external-ip-version=ipv4,port=80 \
  --format json

echo 'Resolving target group id'
export YC_TARGET_GROUP=$(yc load-balancer target-group get --name $YC_PREFIX-target-group --format json | jq .id | tr -d \")
echo "Target group id is $YC_TARGET_GROUP"

echo 'Attaching the target group to the load balancer'
yc load-balancer network-load-balancer attach-target-group \
  --name $YC_PREFIX-network-load-balancer \
  --target-group target-group-id=$YC_TARGET_GROUP,healthcheck-name=test-health-check,healthcheck-interval=2s,healthcheck-timeout=1s,healthcheck-unhealthythreshold=2,healthcheck-healthythreshold=2,healthcheck-http-port=80 \
  --format json

echo 'Pause 50 sec to let load balancer make enough health check pings'
sleep 50

echo 'Checking health of instances in the target group'
yc load-balancer network-load-balancer target-states $YC_PREFIX-network-load-balancer --target-group-id $YC_TARGET_GROUP
