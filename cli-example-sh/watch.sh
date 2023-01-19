#!/bin/bash
export TUTORIAL_SSH_KEY=$(cat ~/.ssh/$TUTORIAL_SSH_KEY_FILE_NAME.pub)

if [ $# -eq 0 ]; then export YC_PREFIX=cli; else export YC_PREFIX=$1; fi

while true; do \
echo $(date);
yc compute instance-group \
  --name ${YC_PREFIX}-instance-group  list-instances; \
yc load-balancer network-load-balancer \
  --name $YC_PREFIX-network-load-balancer target-states \
  --target-group-id $(yc load-balancer target-group  get $YC_PREFIX-target-group --format json | jq .id | tr -d \"); \
sleep 5; done 