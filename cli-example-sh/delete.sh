#!/bin/bash
if [ $# -eq 0 ]; then YC_PREFIX=cli; else YC_PREFIX=$1; fi

echo "Deleting instance group $YC_PREFIX-instance-group"
yc compute instance-group delete $YC_PREFIX-instance-group

echo "Deleting bastion"
yc compute instance delete $YC_PREFIX-bastion

echo "Deleting load balancer "
yc load-balancer network-load-balancer delete $YC_PREFIX-network-load-balancer

echo "Deleting subnets $YC_PREFIX-subnet-a, $YC_PREFIX-subnet-b, $YC_PREFIX-subnet-c"
yc vpc subnet delete $YC_PREFIX-subnet-a $YC_PREFIX-subnet-b $YC_PREFIX-subnet-c

echo "Deleting route table nat-$YC_PREFIX-rt"
yc vpc route-table delete nat-$YC_PREFIX-rt

echo "Deleting gateway nat-$YC_PREFIX-gw"
yc vpc gateway delete nat-$YC_PREFIX-gw

echo "Deleting network $YC_PREFIX-network"
yc vpc network delete $YC_PREFIX-network

echo "Deleting service account $YC_PREFIX-editor-sa"
yc iam service-account delete $YC_PREFIX-editor-sa

