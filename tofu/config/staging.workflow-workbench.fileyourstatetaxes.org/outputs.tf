output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.workflow-workbench.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.workflow-workbench.cloudfront_domain_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.workflow-workbench.api_gateway_url
}

output "document_storage_bucket" {
  description = "S3 bucket name for document storage"
  value       = module.workflow-workbench.document_storage_bucket
}

output "website_bucket" {
  description = "S3 bucket name for website hosting"
  value       = module.workflow-workbench.website_bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.workflow-workbench.dynamodb_table_name
}

output "lambda_functions" {
  description = "Map of Lambda function names"
  value       = module.workflow-workbench.lambda_functions
}
