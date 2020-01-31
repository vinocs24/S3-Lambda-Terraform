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

#cloudtrail

resource "aws_cloudtrail" "example" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.example-CT.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  
  tags = {
    Name        = "s3-cloudtrail"
 
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


#cloudwatch log group

resource "aws_cloudwatch_log_group" "log_group_tf" {
  name = "cloudtrail-log-group_tf"
}

resource "aws_iam_role" "logging_role_tf" {
  name = "cloudwatch-logging-role-tf_new"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "logging_policy_tf" {
  name = "cloudwatch-logging-policy-tf"
  role = aws_iam_role.logging_role_tf.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        aws_cloudwatch_log_group.log_group_tf.arn
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        aws_cloudwatch_log_group.log_group_tf.arn
      ]
    }
  ]
}
POLICY
}

#aws sns topic

resource "aws_sns_topic" "bucket_alerts" {
  name = "s3-bucket-public-access-alert-tf"

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint var.alert_email_address"
  }
}


#IAM Role:

resource "aws_iam_role" "iam_for_s3_lambda_tf" {
  name = "iam_for_s3_lambda_tf"

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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "bucket-alert-lambda-execution-policy-tf"
  role = aws_iam_role.iam_for_s3_lambda_tf.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "sns:Publish",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:sns:us-east-1:961508331227:s3-bucket-public-access-alert-tf",
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Sid": "S3GetBucketACLandPolicy",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketAcl",
                "s3:GetBucketPolicy"
            ],
            "Resource": "*"
        },
		{
            "Sid": "S3PutBucketACLAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutBucketAcl",
                "s3:PutBucketPolicy"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "LambdaBasicExecutionAccess",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


/*
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
*/



# Archive a single file.

data "archive_file" "Test" {
  type        = "zip"
  source_file = "Test.py"
  output_path = "Test.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "Test.zip"
  function_name = "s3-filemove"
  role          = aws_iam_role.iam_for_s3_lambda_tf.arn
  handler       = "Test.lambda_handler"
  source_code_hash = "filebase64sha256(Test.zip)"
  runtime = "python3.7"
  environment {
    variables = {
      snsTopicArn = aws_sns_topic.bucket_alerts.arn
    }
  }
}


#Cloudwatch
resource "aws_cloudwatch_event_rule" "test-rule" {
  name                = "example-cw-rule"
  description         = "S3 event log"
  depends_on = [aws_lambda_function.test_lambda]
  
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

/*
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
      "PutObject"
    ],
    "requestParameters": {
      "bucketName": [
        "my-tf-test-bucket-dev"
      ]
    }
  }
}
PATTERN
}
*/


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
  source_arn    = aws_cloudwatch_event_rule.test-rule.arn
}

