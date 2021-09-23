provider "aws" {
  region = var.region
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