#!/bin/bash

candidate=$1
branch=$2
dry_run=$3
branch=${branch:-"main"}
dry_run=${dry_run:-"false"}

# Generate random candidate ID if not provided
if [ -z "$candidate" ]; then
  candidate=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 12)
  echo "No candidate specified, generated random ID: $candidate"
fi

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

if [ "$dry_run" = "true" ]; then
  echo "=== DRY RUN MODE ==="
  echo "Candidate: $candidate"
  echo "Branch: $branch"
  echo "Cluster Name: $EKS_CLUSTER_NAME"
  echo ""
  echo "Rendering CloudFormation template..."
  bash $SCRIPT_DIR/build-ide-cfn.sh "-"
  echo ""
  echo "=== DRY RUN COMPLETE (no deployment executed) ==="
else
  outfile=$(mktemp)
  bash $SCRIPT_DIR/build-ide-cfn.sh $outfile
  aws cloudformation deploy --stack-name "$EKS_CLUSTER_NAME-ide" \
    --capabilities CAPABILITY_NAMED_IAM --disable-rollback \
    --parameter-overrides Candidate="$candidate" RepositoryRef="$branch" \
    --template-file $outfile
fi