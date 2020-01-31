variable "source-bucket-name" {
  description = "Source Bucket Name"
  default     = "my-tf-test-bucket-dev123"
}

variable "destination-bucket-name" {
  description = "Destination Bucket Name"
  default     = "my-tf-test-bucket-val123"
}

variable "CT-bucket-name" {
  description = "CloudTrail Bucket Name"
  default     = "ct-log-demo123456"
}

variable "function_name" {
  default = "minimal_lambda_function"
}

variable "handler" {
  default = "lambda.handler"
}

variable "runtime" {
  default = "python3.6"
}

variable "trail_name" {
  default = "s3-cloudtrail-log-new"
}

variable "alert_email_address" {
  description = "Please Provide Email-id"
  default = "vinocs24@gmail.com"
}
