# Chainguard Interview Environment

Shamelessly cannibalized from the [EKS Workshop](https://github.com/aws-samples/eks-workshop-v2).

## Instructions for use

The setup process requires local AWS credentials to deploy the environment. Ensure those are working first before proceeding:

```shell
aws sts get-caller-identity
```

Clone the repository to your local environment:

```shell
git clone https://github.com/JoeNorth/cg-interview-environment.git && cd cg-interview-environment
```

Run the `deploy-ide` command:

```shell
make deploy-ide
```

From the [CloudFormation Console](https://us-west-2.console.aws.amazon.com/cloudformation/home) select the `cg-interview-ide` stack and go to the `Outputs` tab. Click the link for the `IdePasswordSecret` which will take you to the [Secrets Manager](https://console.aws.amazon.com/secretsmanager/secret?name=cg-interview-ide-password) console.

From the Secrets Manager console click the `Retrieve secret value` button which will show the IDE password. Copy this password to your clipboard.

![screenshot of the secrets manager console showing the retriece secret value button](images/image.png)

From the CloudFormation stack's `Outputs` tab click on the `IdeUrl` link which will take you to the `code-server` login page. Enter the password copied from Secrets Manager and click `Login`.

From the terminal in the `code-server` environment, run `create-cluster` which will create the EKS cluster for the interview.

Complete the steps from the interview guide to clone the necessary repositories for the interview materials and deploy them to the cluster.