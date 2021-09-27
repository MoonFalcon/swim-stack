# Swim-Stack

## About the project

This repository contains a helm chart that installs mongo and the `devops-practical` node.js application as well as terraform files to build out an EKS cluster and its dependencies.

## Design

### Terraform structure:

- There are two separate terraform projects in this repo, `swim-stack-terraform` and `terraform-state-backend`.
- `terraform-state-backend` creates a private S3 bucket to hold all of the terraform state files. 
- `swim-stack-terraform` creates all the other infrastructure necessary to host a k8s service over https
- `swim-stack-terraform` files are broken into three modules; the root module, `cluster` and `certs`.
    - `cluster` stands up the cluster and networking dependencies
    - `certs` stands up all certificate infrastructure with `cert-manager`
    - The root module references these and also creates an ecr repo to host our `devops-practical` application images

### VPC

- The networking configuration is simple and somewhat resillient. There is one VPC with 3 subnets that are split between all the `us-west-2` availability zones.

### EKS

- The cluster contains one nodegroup that is split equally between the 3 availability zones, giving us N+1 tolerance. The cluster hosts cert-manager which utilizes the letsencrypt production issuer to provide certificates for ingress. 

## Setup

1. Configure your ~/.aws config and credentials to connect to your AWS account. Depending on your setup you may need to set your AWS_PROFILE environment variable.
1. Apply the terraform files in order:

    ``` bash
    # Create an s3 bucket to securely store the terraform state
    cd terraform-state-backend
    terraform init; terraform apply (yes)

    # Create everything else (VPC, EKS, Helm deployments)
    cd swim-stack-terraform
    terraform init; terraform apply (yes)
    ```

1. You must build and upload the devops-practical image yourself as this repo doesn't include CI scripts (yet). [Guide to pushing a docker image to ECR here](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html).

1. Run `aws eks list-clusters` and then insert the result into `aws eks update-kubeconfig --name $RESULT`

1. Install the devops-practical helm chart with `helm install devops-practical ./devops-practical -n swimlane`

1. Route DNS to your new elb via a cname record. In my case I can hit https://swimstack.isaacsmothers.com which forwards to my elb over port 443 and then to the internal service over port 3000

## Proof of working application on https

![Success](success.png?raw=true)

## Not handled in this project:

- Custom godaddy domain with ns records from route 53 (I now own isaacsmothers.com, woot!)
- `A` record (`swimstack.isaacsmothers.com`) pointing to ELB / ingress for the cluster!
![r53](r53.png?raw=true)
- Devops-Practical docker image uploaded to ecr
- AWS account creation

## To-do:

- Ansible NTP configuration on terraform created nodes