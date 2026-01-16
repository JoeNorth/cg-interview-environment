#!/bin/bash

candidate=$1
branch=$2
branch=${branch:-"main"}

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

outfile=$(mktemp)

bash $SCRIPT_DIR/build-ide-cfn.sh $outfile

aws cloudformation deploy --stack-name "$EKS_CLUSTER_NAME-ide" \
  --capabilities CAPABILITY_NAMED_IAM --disable-rollback \
  --parameter-overrides Candidate="$candidate" RepositoryRef="$branch" \
  --template-file $outfile