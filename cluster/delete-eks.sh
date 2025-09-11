#!/bin/bash
CLUSTER_NAME="prod-eks"
REGION="us-east-1"

eksctl delete cluster --name $CLUSTER_NAME --region $REGION
