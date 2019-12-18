# Use AWS Terraform provider
provider "aws" {
  region = "us-west-2"
}

# Create S3 Bucket
resource "aws_s3_bucket" "b" {
  bucket = "my-tf-test-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "b1" {
  bucket = "my-tf-test-bucket1"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
