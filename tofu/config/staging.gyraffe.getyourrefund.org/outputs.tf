output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.gyraffe.log_bucket
}

output "docker_push" {
  description = "Display commands to push the Docker image to ECR."
  value = module.gyraffe.docker_push
}

output "repository_arn" {
  description = "AWS Repository Amazon Resource Name (ARN) for ECR"
  value = module.gyraffe.repository_arn
}

output "repository_url" {
  description = "AWS Repository URL for ECR"
  value = module.gyraffe.repository_url
}

output "submission_bundles_bucket_name" {
  description = "S3 bucket where submission bundles are stored"
  value = module.gyraffe.submission_bundles_bucket_name
}
