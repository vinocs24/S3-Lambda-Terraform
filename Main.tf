# Use AWS Terraform provider
provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}



# Create S3 Bucket
resource "aws_s3_bucket" "example-dev" {
  bucket = var.source-bucket-name
  acl    = "private"

  tags = {
    Name        = "My bucket- Dev"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "example-val" {
  bucket = var.destination-bucket-name
  acl    = "private"

  tags = {
    Name        = "My bucket- Val"
    Environment = "vel"
  }
}






