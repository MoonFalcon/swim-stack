# Swim-Stack

## About the project

This repository contains a helm chart that installs mongo and the `devops-practical` node.js application as well as terraform files to build out an EKS cluster and its dependencies. Certificates are managed with cert-manager.

## Design

The cluster contains one nodegroup that is split equally between 3 availability zones. The cluster hosts cert-manager which utilizes the letsencrypt production issuer to provide certificates for ingress.

## Setup

1. Apply the terraform files:

    ```
    cd swim-stack-terraform
    terraform init
    terraform validate; terraform apply (yes)
    ```

1. You must build and upload the devops-practical image yourself as this repo doesn't include CI scripts (yet). [Guide to pushing a docker image to ECR here](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html).

1. Run `aws eks list-clusters` and then insert the result into `aws eks update-kubeconfig --name $RESULT`

1. Install the devops-practical helm chart with `helm install devops-practical ./devops-practical -n swimlane`

1. Route DNS to your new elb via a cname record. In my case I can hit swimstack.isaacsmothers.com:3000

## Proof of working application on https
![Success](success.png?raw=true)

## Not captured in this project:

- Custom godaddy domain with ns records from route 53 (I now own isaacsmothers.com, woot!)
- `A` record (`swimstack.isaacsmothers.com`) pointing to ELB / ingress for the cluster!
![r53](r53.png?raw=true)
- Devops-Practical docker image uploaded to ecr
- AWS account creation

## To-do:
- Ansible NTP configuration on terraform created nodes
- Value abstraction