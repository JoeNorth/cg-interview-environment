#!/bin/bash

candidate=$1
branch=$2
dry_run=$3

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Skip AWS credential checks in dry-run mode
if [ "$dry_run" = "true" ]; then
  export SKIP_CREDENTIALS=true
fi

source $SCRIPT_DIR/lib/common-env.sh

if [ "$dry_run" = "true" ]; then
  echo "Candidate Name: ${candidate:-<none>}"
  echo "Cluster Name: $EKS_CLUSTER_NAME"
  echo "Commands that would be executed:"
  echo "  aws cloudformation delete-stack --stack-name \"$EKS_CLUSTER_NAME-ide\""
  echo "  aws cloudformation wait stack-delete-complete --stack-name \"$EKS_CLUSTER_NAME-ide\""
else
  echo "Destroying IDE environment for candidate: $candidate"
  echo "Cluster Name: $EKS_CLUSTER_NAME"
  echo ""

  aws cloudformation delete-stack --stack-name "$EKS_CLUSTER_NAME-ide"
  aws cloudformation wait stack-delete-complete --stack-name "$EKS_CLUSTER_NAME-ide"
fi