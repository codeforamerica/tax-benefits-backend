output "heroku_access_key_id" {
  description = "AWS access key ID for Heroku review apps."
  value       = aws_iam_access_key.heroku.id
  sensitive   = true
}

output "heroku_secret_access_key" {
  description = "AWS secret access key for Heroku review apps."
  value       = aws_iam_access_key.heroku.secret
  sensitive   = true
}

output "schemas_bucket_name" {
  description = "S3 bucket name for schemas."
  value       = local.schemas_bucket_name
}
