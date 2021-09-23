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

# Add custom swimlane namespace for our apps to live in
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

  depends_on = [module.eks]
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

# Install cert-manager into the cluster
module "cert_manager" {
  source        = "terraform-iaac/cert-manager/kubernetes"

  cluster_issuer_email                   = "isaacsmothers@yahoo.com"
  cluster_issuer_name                    = "cert-manager-global"
  cluster_issuer_private_key_secret_name = "cert-manager-private-key"
  # cluster_issuer_create = false
}

# Install prod certificate issuer
resource "helm_release" "letsencrypt" {
  name       = "letsencrypt"
  chart      = "./letsencrypt"
  namespace = "swimlane"

  depends_on = [module.cert_manager]
}

# ECR repo to host the image utilized by the devops-practical helm chart
resource "aws_ecr_repository" "devops-practical" {
  name                 = "devops-practical"

  image_scanning_configuration {
    scan_on_push = true
  }
}