# Use AWS Terraform provider
provider "aws" {
  region = "us-west-2"
}

# Create S3 Bucket 1
resource "aws_s3_bucket" "example-dev" {
  bucket = var.source-bucket-name
  acl    = "private"

  tags = {
    Name        = "My bucket-Dev"
    Environment = "Dev"
  }
}

# Create S3 Bucket 2
resource "aws_s3_bucket" "example-val" {
  bucket = var.destination-bucket-name
  acl    = "private"

  tags = {
    Name        = "My bucket-Val"
    Environment = "vel"
  }
}


resource "aws_lambda_function" "lambda_function" {
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = var.handler
  runtime          = var.runtime
  #filename         = "lambda.zip"
  function_name    = var.function_name
  #source_code_hash = base64sha256(file("lambda.zip"))
}

resource "aws_iam_role" "lambda_exec_role" {
  name        = "lambda_exec"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
