variable "source-bucket-name" {
  description = "Source Bucket Name"
  default     = "my-tf-test-bucket-dev"
}

variable "destination-bucket-name" {
  description = "Destination Bucket Name"
  default     = "my-tf-test-bucket-val"
}

variable "CT-bucket-name" {
  description = "CloudTrail Bucket Name"
  default     = "CT-log-demo12345"
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
  default = "s3-cloudtrail-log"
}


