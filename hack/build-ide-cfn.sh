#!/bin/bash

set -e

output_path=$1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/lib/common-env.sh

export Env="${EKS_CLUSTER_NAME}"

cd  $SCRIPT_DIR/../lab

# If output_path is "-", output to stdout for dry-run mode
if [ "$output_path" = "-" ]; then
  cat cfn/cg-interview-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env'
elif [ -z "$output_path" ]; then
  outfile=$(mktemp)
  cat cfn/cg-interview-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env' > $outfile
  echo "Output file: $outfile"
else
  outfile=$output_path
  cat cfn/cg-interview-vscode-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env' > $outfile
  echo "Output file: $outfile"
fi
