output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}

output "document_storage_bucket" {
  description = "S3 bucket name for document storage"
  value       = aws_s3_bucket.document_storage.id
}

output "website_bucket" {
  description = "S3 bucket name for website hosting"
  value       = aws_s3_bucket.website.id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.extracted_data.name
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.queue_to_dynamo.url
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = local.kms_key_id
}

output "lambda_functions" {
  description = "Map of Lambda function names"
  value = {
    authenticate          = aws_lambda_function.authenticate.function_name
    text_extract         = aws_lambda_function.text_extract.function_name
    s3_file_upload       = aws_lambda_function.s3_file_upload.function_name
    get_extracted_document = aws_lambda_function.get_extracted_document.function_name
    sqs_dynamo_writer    = aws_lambda_function.sqs_dynamo_writer.function_name
  }
}

output "log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    api_gateway = aws_cloudwatch_log_group.api_gateway.name
    lambda = {
      authenticate          = aws_cloudwatch_log_group.lambda_authenticate.name
      text_extract         = aws_cloudwatch_log_group.lambda_text_extract.name
      s3_file_upload       = aws_cloudwatch_log_group.lambda_s3_file_upload.name
      get_extracted_document = aws_cloudwatch_log_group.lambda_get_extracted_document.name
      sqs_dynamo_writer    = aws_cloudwatch_log_group.lambda_sqs_dynamo_writer.name
    }
  }
}

output "security_groups" {
  description = "Map of security group IDs"
  value = {
    lambda = local.lambda_security_group_id
  }
}