data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = var.region
}


resource "random_id" "cluster-suffix" {
  byte_length = 1
}

locals {
  cluster_name = "swimstack-${random_id.cluster-suffix.id}"
}

# Create 1 public and private subnet per availability zone
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "swimstack-vpc"
  cidr                 = "10.0.0.0/22"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]
  public_subnets       = ["10.0.0.192/26", "10.0.1.0/26", "10.0.1.64/26"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Build the EKS cluster and worker nodes (1 per az in us-west-2)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = "swimstack"
  }

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                 = "nodegroup-1"
      instance_type        = "t2.small"
      asg_desired_capacity = 3
      root_volume_type     = "gp2"
    }
  ]

  depends_on = [
    module.vpc
  ]
}

provider "helm" {
  kubernetes {
    # config_path = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

# Install the ingress-nginx controller
resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  depends_on = [
    module.eks
  ]
}

# Install the cert-manager chart
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    module.eks
  ]
}

# Install prod certificate issuer
resource "helm_release" "letsencrypt" {
  name       = "letsencrypt"
  chart      = "./letsencrypt"
  namespace = "swimlane"
  create_namespace = true

  depends_on = [helm_release.cert_manager]
}

# ECR repo to host the image utilized by the devops-practical helm chart
resource "aws_ecr_repository" "devops-practical" {
  name                 = "devops-practical"

  image_scanning_configuration {
    scan_on_push = true
  }
}