# Use AWS Terraform provider
provider "aws" {
  region = "us-west-2"
}

# Create S3 Bucket 1
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "example-dev" {
  bucket = var.source-bucket-name
  acl    = "private"
  
  tags = {
    Name        = "My bucket-dev"
    Environment = "dev"
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

# Create S3 Bucket for cloudtrail
resource "aws_s3_bucket" "example-CT" {
  bucket = var.CT-bucket-name
  acl    = "private"
  force_destroy = true
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::ct-log-demo123456"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::ct-log-demo12345/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

  tags = {
    Name        = "My bucket-CT"
    Environment = "cloudtrail"
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
                "arn:aws:s3:::my-tf-test-bucket-dev",
                "arn:aws:s3:::my-tf-test-bucket-val"
            ]
        },
        {
            "Sid": "SourceBucketGetObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::my-tf-test-bucket-dev/*"
        },
        {
            "Sid": "DestinationBucketPutObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::my-tf-test-bucket-val/*"
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
  role          = aws_iam_role.iam_for_s3_lambda.arn
  handler       = "Test.lambda_handler"
  source_code_hash = "filebase64sha256(Test.zip)"

  runtime = "python3.7"
}


#Cloudwatch
resource "aws_cloudwatch_event_rule" "test-rule" {
  name                = "example-cw-rule"
  description         = "S3 event log"
  
depends_on = [
    "aws_lambda_function.test_lambda"
  ]

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutBucketAcl",
	  "PutBucketPolicy",
      "CreateBucket"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "cloud-wtc" {
    rule = aws_cloudwatch_event_rule.test-rule.name
    target_id = "s3-filemove"
    arn = aws_lambda_function.test_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_event_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.test_rule.arn
}

#cloudtrail

resource "aws_cloudtrail" "example" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.example-CT.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  /*enable_logging                = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true


  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
*/
  tags = {
    Name        = "s3-cloudtrail"
 
  }
}
