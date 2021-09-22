resource "aws_ecr_repository" "devops-practical" {
  name                 = "devops-practical"

  image_scanning_configuration {
    scan_on_push = true
  }
}