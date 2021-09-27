resource "aws_s3_bucket" "tf_s3_state" {
  bucket = "terraform-state-swimstack"
  acl    = "private"
  versioning {
    enabled = true
  }

  tags = {
    Name = "Terraform state files"
  }
}