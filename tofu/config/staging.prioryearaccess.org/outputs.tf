output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.logging.bucket
}

# Display commands to push the Docker image to ECR.
output "docker_push" {
  value = module.web.docker_push
}

output "repository_arn" {
  value = module.web.repository_arn
}

output "repository_url" {
  value = module.web.repository_url
}
