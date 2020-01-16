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

#IAM Role:

resource "aws_iam_role" "iam_for_s3_lambda" {
  name = "iam_for_s3_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_lambda_policy" {
  name        = "s3_lambda_policy"
  description = "A test policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListSourceAndDestinationBuckets",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            "Resource": [
                "arn:aws:s3:::test-bucket-for-transfer-check",
                "arn:aws:s3:::serverless-demo-s3-bucket"
            ]
        },
        {
            "Sid": "SourceBucketGetObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::test-bucket-for-transfer-check/*"
        },
        {
            "Sid": "DestinationBucketPutObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::serverless-demo-s3-bucket/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_for_s3_lambda.name
  policy_arn = aws_iam_policy.s3_lambda_policy.arn
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
