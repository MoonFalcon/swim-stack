# Swim-Stack

## DRAFT

This repository hosts terraform files to spin up a new cluster and provide neccesary infrastructure for the devops-practical application. 

This repo also contains a devops-practical helm chart. 

```
- devops-practical # Helm chart for the devops-practical swimlane application
- swim-stack-terraform # Contains terraform files to instantiate dependencies for the devops-practical chart, including an environment to run in (Used services so far: EKS, ECR, VPC)
```

## Todo:

- Figure out / fix redirection issue with devops-practical
- Codify cert-manager helm chart install (with tf)

...