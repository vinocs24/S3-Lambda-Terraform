# Use AWS Terraform provider
/*provider "aws" {
  region = "us-west-2"
}*/

# Create S3 Bucket
resource "aws_s3_bucket" "example-dev" {
  bucket = "my-tf-test-bucket-dev"
  acl    = "private"

  tags = {
    Name        = "My bucket- Dev"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "example-val" {
  bucket = "my-tf-test-bucket-val"
  acl    = "private"

  tags = {
    Name        = "My bucket- Val"
    Environment = "vel"
  }
}
