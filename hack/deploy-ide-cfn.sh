#!/bin/bash

candidate=$1
branch=$2
dry_run=$3
# If branch not specified, use current git branch or default to main
if [ -z "$branch" ]; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
fi
dry_run=${dry_run:-"false"}

# Generate random candidate ID if not provided
if [ -z "$candidate" ]; then
  candidate=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 12)
  echo "No candidate specified, generated random ID: $candidate"
fi

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Extract repository owner and name from git remote origin
detect_git_repo() {
  local remote_url=$(git remote get-url origin 2>/dev/null || echo "")

  if [ -z "$remote_url" ]; then
    # No git remote found, use CloudFormation defaults
    echo "JoeNorth" "cg-interview-environment"
    return
  fi

  # Parse SSH format: git@github.com:owner/repo.git
  # Parse HTTPS format: https://github.com/owner/repo.git
  local owner=""
  local repo=""

  if [[ "$remote_url" =~ git@github\.com:([^/]+)/([^.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ https://github\.com/([^/]+)/([^.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  else
    # Couldn't parse, use defaults
    echo "JoeNorth" "cg-interview-environment"
    return
  fi

  echo "$owner" "$repo"
}

# Detect repository info
read repo_owner repo_name < <(detect_git_repo)

source $SCRIPT_DIR/lib/common-env.sh

if [ "$dry_run" = "true" ]; then
  echo "=== DRY RUN MODE ==="
  echo "RepositoryOwner: $repo_owner"
  echo "RepositoryName: $repo_name"
  echo "RepositoryRef: $branch"
  echo "Candidate: $candidate"
  echo "Cluster Name: $EKS_CLUSTER_NAME"
  echo ""
  echo "Rendering CloudFormation template..."
  bash $SCRIPT_DIR/build-ide-cfn.sh "-"
  echo ""
  echo "=== DRY RUN COMPLETE (no deployment executed) ==="
else
  echo "Deploying IDE environment..."
  echo "Candidate: $candidate"
  echo "Repository: $repo_owner/$repo_name"
  echo "Branch: $branch"
  echo "Cluster Name: $EKS_CLUSTER_NAME"
  echo ""

  outfile=$(mktemp)
  bash $SCRIPT_DIR/build-ide-cfn.sh $outfile
  aws cloudformation deploy --stack-name "$EKS_CLUSTER_NAME-ide" \
    --capabilities CAPABILITY_NAMED_IAM --disable-rollback \
    --parameter-overrides Candidate="$candidate" RepositoryRef="$branch" \
      RepositoryOwner="$repo_owner" RepositoryName="$repo_name" \
    --template-file $outfile
fi