terraform {
  backend "s3" {
    bucket = "terraform-state-swimstack"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.region
}

# ECR repo to host the image utilized by the devops-practical helm chart
resource "aws_ecr_repository" "devops-practical" {
  name = "devops-practical"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "cluster" {
  source = "./modules/cluster"
}

module "certs" {
  source = "./modules/certs"
  cluster_id = module.cluster.cluster_id
}