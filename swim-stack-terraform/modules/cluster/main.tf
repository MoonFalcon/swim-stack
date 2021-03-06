data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_availability_zones" "available" {}

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
      name                 = "default"
      instance_type        = "t2.small"
      asg_desired_capacity = 3
      root_volume_type     = "gp2"
    }
  ]

  depends_on = [
    module.vpc
  ]
}

output "cluster_id" {
  value = module.eks.cluster_id
}