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
}

resource "kubernetes_namespace" "swimlane" {
  metadata {
    annotations = {
      name = "swimlane"
    }

    labels = {
      name = "swimlane"
    }

    name = "swimlane"
  }
}