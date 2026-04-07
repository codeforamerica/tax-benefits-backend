output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.logging.bucket
}

output "docker_push" {
  description = "Display commands to push the Docker image to ECR."
  value       = module.web.docker_push
}

output "repository_arn" {
  description = "AWS Repository Amazon Resource Name (ARN) for ECR"
  value       = module.web.repository_arn
}

output "repository_url" {
  description = "AWS Repository URL for ECR"
  value       = module.web.repository_url
}

output "submission_bundles_bucket_name" {
  description = "S3 bucket where submission bundles are stored"
  value       = module.submission_bundles.bucket
}

output "db_user_secret_arns" {
  description = "Secrets Manager ARNs for any database users created with credentials."
  value       = module.database.db_user_secret_arns
}

output "vpc_peer_ids" {
  description = "The IDs of any created VPC peering connections."
  value       = module.vpc.peer_ids
}
