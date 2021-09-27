variable "cluster_id" {
  type = string
  description = "The id of the EKS"
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_id
}

provider "helm" {
  kubernetes {
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
}

# Install the cert-manager chart
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    helm_release.ingress-nginx
  ]
}

# Install prod certificate issuer
resource "helm_release" "letsencrypt" {
  name             = "letsencrypt"
  chart            = "modules/certs/letsencrypt"
  namespace        = "swimlane"
  create_namespace = true

  depends_on = [helm_release.cert_manager]
}