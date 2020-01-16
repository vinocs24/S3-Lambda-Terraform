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

# Archive a single file.

data "archive_file" "Test" {
  type        = "zip"
  source_file = "Test.py"
  output_path = "Test.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "Test.zip"
  function_name = "s3-filemove"
  role          = aws_iam_role.s3-lambda.arn
  handler       = "Test.lambda_handler"
  source_code_hash = "filebase64sha256(Test.zip)"

  runtime = "python3.7"
}
