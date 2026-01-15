# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository provides an AWS-based interview environment for Chainguard. It provisions:
- An EC2-based IDE (code-server) via CloudFormation
- An EKS cluster via eksctl for Kubernetes-based interview scenarios
- IAM roles with carefully scoped permissions for the interview environment

The project is derived from the AWS EKS Workshop codebase.

## Key Commands

### Deployment

```bash
# Deploy the IDE infrastructure (CloudFormation stack with EC2 + code-server)
make deploy-ide

# Deploy the IDE for a specific environment (prefixes cluster name)
make deploy-ide environment=test

# Destroy the IDE infrastructure
make destroy-ide
```

### Cluster Operations (from within the IDE)

The following commands are available as bash functions within the code-server IDE environment:

```bash
# Create the EKS cluster using eksctl
create-cluster

# Delete the EKS cluster and cleanup resources
delete-cluster

# Use an existing cluster
use-cluster <cluster-name>
```

### Local Development Commands

```bash
# Open a shell in the Docker container for the specified environment
make shell environment=<env-name>

# Open the IDE in the container
make ide environment=<env-name>
```

### Infrastructure Management

```bash
# Create EKS cluster infrastructure (called by create-cluster)
bash hack/create-infrastructure.sh [environment]

# Destroy EKS cluster and cleanup
bash hack/destroy-infrastructure.sh [environment]

# Update IAM role policies
bash hack/update-iam-role.sh [environment]
```

## Architecture

### Environment Naming

The system uses an optional `environment` parameter to support multiple parallel deployments:
- Without environment: cluster name is `cg-interview`
- With environment: cluster name is `cg-interview-${environment}`

This allows multiple interview environments to coexist in the same AWS account.

### Two-Layer Infrastructure

**Layer 1: IDE Environment (CloudFormation)**
- Stack: `${EKS_CLUSTER_NAME}-ide`
- Template: `lab/cfn/cg-interview-vscode-cfn.yaml`
- Creates: VPC, EC2 instance running code-server, security groups, IAM role
- The IDE provides a browser-based VS Code environment for interviewees

**Layer 2: IAM Role (CloudFormation)**
- Stack: `${EKS_CLUSTER_NAME}-ide-role`
- Template: `lab/iam/iam-role-cfn.yaml`
- The template uses a special syntax: `file: ./iam/policies/xyz.yaml`
- Build process (`hack/build-ide-cfn.sh`) uses `yq` to inline these policy files
- Policies are split into multiple files for organization:
  - `base.yaml`: Core AWS permissions
  - `iam.yaml`: IAM management
  - `ec2.yaml`: EC2 operations
  - `labs1.yaml`, `labs2.yaml`, `labs3.yaml`: Lab-specific permissions
  - `troubleshoot.yaml`: Troubleshooting permissions

**Layer 3: EKS Cluster (eksctl)**
- Cluster definition: `cluster/eksctl/cluster.yaml`
- Uses environment variable substitution (`envsubst`) for:
  - `${EKS_CLUSTER_NAME}`: Cluster name
  - `${AWS_REGION}`: AWS region (defaults to us-west-2)
- Configuration:
  - 3-node managed node group (m5.large)
  - VPC CIDR: 10.42.0.0/16
  - Kubernetes version: 1.33
  - Addons: kube-proxy, vpc-cni, coredns, aws-ebs-csi-driver

### Shell Script Organization

- `hack/lib/common-env.sh`: Environment variable setup and defaults
- `hack/exec.sh`: Execute commands in the Docker container
- `hack/shell.sh`: Interactive shell in the Docker container
- `hack/deploy-ide-cfn.sh`: Deploy IDE CloudFormation stack
- `hack/build-ide-cfn.sh`: Build CloudFormation template (inlines policy files)
- `hack/destroy-ide-cfn.sh`: Destroy IDE CloudFormation stack
- `hack/create-infrastructure.sh`: Create EKS cluster
- `hack/destroy-infrastructure.sh`: Destroy EKS cluster
- `hack/update-iam-role.sh`: Update IAM role stack

### Docker Container Build

The IDE environment is built using a Dockerfile (`lab/Dockerfile`):
- Base: Amazon Linux 2023
- User: ec2-user (non-root)
- Tools installed: kubectl, eksctl, helm, aws-cli, Docker, yq, jq, etc.
- Scripts:
  - `lab/scripts/installer.sh`: Install CLI tools
  - `lab/scripts/code-server.sh`: Install code-server
  - `lab/scripts/setup.sh`: Configure bashrc and environment
  - `lab/scripts/entrypoint.sh`: Container entrypoint
- Utility binaries in `lab/bin/`: Helper scripts for cluster operations

### CloudFormation Template Processing

The IAM role CloudFormation template uses a custom syntax for including external files:

```yaml
PolicyDocument:
  file: ./iam/policies/base.yaml
```

The `hack/update-iam-role.sh` script processes this by:
1. Using `yq` to find nodes with `file:` keys
2. Loading the referenced YAML file content
3. Replacing the `file:` reference with the actual content
4. Using `envsubst` to replace `${Env}` with `${EKS_CLUSTER_NAME}`

Command: `cat iam/iam-role-cfn.yaml | yq '(.. | select(has("file"))) |= (load(.file))' | envsubst '$Env'`

### Interview Scenario Setup

The `create-cluster` function (defined in `lab/scripts/setup.sh`):
1. Fetches the eksctl cluster config from GitHub
2. Creates the EKS cluster
3. Applies a StorageClass for EBS volumes (`questions/ebs-sc.yaml`)
4. Installs a WordPress Helm chart from `ghcr.io/max-allan-cgr/helm-charts/wordpress`

The interview questions/scenarios are stored in the `questions/` directory.

## Important Implementation Details

### Environment Variables

Key environment variables (set in `hack/lib/common-env.sh`):
- `EKS_CLUSTER_NAME`: Derived from optional environment parameter
- `AWS_REGION`: Defaults to us-west-2 if not set
- `IDE_ROLE_NAME`: `${EKS_CLUSTER_NAME}-ide-role`
- `IDE_ROLE_ARN`: Constructed from account ID and role name

### Bash Function Aliases

The code-server environment includes these bash functions (in `~/.bashrc.d/aliases.bash`):
- `create-cluster`: Create EKS cluster and install WordPress
- `delete-cluster`: Uninstall WordPress, delete PVCs, delete cluster
- `use-cluster`: Switch kubectl context to a different cluster
- `prepare-environment`: Reset environment for a lab module

### Repository References

The system supports customization via environment variables:
- `REPOSITORY_OWNER`: GitHub org/user (default: JoeNorth)
- `REPOSITORY_NAME`: GitHub repo (default: cg-interview-environment)
- `REPOSITORY_REF`: Git branch/tag (default: main)

These allow the IDE to pull cluster configs and scripts from a forked/modified repository.

## Working with This Codebase

### Modifying IAM Policies

IAM policies are in `lab/iam/policies/*.yaml`. After modifying:
```bash
bash hack/update-iam-role.sh [environment]
```

This updates the CloudFormation stack with the new policies.

### Modifying the Cluster Configuration

Edit `cluster/eksctl/cluster.yaml`. The configuration supports environment variable substitution for dynamic values like cluster name and region.

### Modifying the IDE Environment

The IDE configuration is in `lab/cfn/cg-interview-vscode-cfn.yaml`. After changes:
```bash
make deploy-ide environment=<env-name>
```

### Testing Locally

Use the Docker container to test scripts without deploying to AWS:
```bash
make shell environment=test
```

This gives you an interactive shell with all the tools installed.

## Security Considerations

- The IAM role has broad permissions suitable for interview scenarios
- The IDE is accessible via a public URL with password authentication
- Password is stored in AWS Secrets Manager
- The EC2 instance uses instance profiles for AWS credentials
- Network access is restricted via security groups with S3 prefix lists

## Dependencies

- AWS CLI
- Docker (for local container development)
- make
- bash
- yq (for YAML processing)
- envsubst (for template variable substitution)
