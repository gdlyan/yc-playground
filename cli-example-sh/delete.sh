#!/bin/bash
if [ $# -eq 0 ]; then YC_PREFIX=cli; else YC_PREFIX=$1; fi

echo "Deleting instance group $YC_PREFIX-instance-group"
yc compute instance-group delete $YC_PREFIX-instance-group

echo "Deleting load balancer "
yc load-balancer network-load-balancer delete $YC_PREFIX-network-load-balancer

echo "Deleting subnets $YC_PREFIX-subnet-a, $YC_PREFIX-subnet-b, $YC_PREFIX-subnet-c"
yc vpc subnet delete $YC_PREFIX-subnet-a $YC_PREFIX-subnet-b $YC_PREFIX-subnet-c
echo 'Done, this is the list of the remaining subnets'
yc vpc subnet list

echo "Deleting network $YC_PREFIX-network"
yc vpc network delete $YC_PREFIX-network
echo 'Done, this is the list of the remaining networks'
yc vpc network list

echo "Deleting service account $YC_PREFIX-editor-sa"
yc iam service-account delete $YC_PREFIX-editor-sa

