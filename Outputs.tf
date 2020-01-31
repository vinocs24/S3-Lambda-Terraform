output "function_arn" {
  value       = aws_lambda_function.test_lambda.arn
}

output "source_bucket" {
  value       = aws_s3_bucket.example-dev.arn 
}

output "desc_bucket" {
  value       = aws_s3_bucket.example-val.arn
}
