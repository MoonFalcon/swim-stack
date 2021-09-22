provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "devops-practical" {
  name       = "devops-practical"
  chart      = "../devops-practical/devops-practical"
  namespace = "swimlane"
}