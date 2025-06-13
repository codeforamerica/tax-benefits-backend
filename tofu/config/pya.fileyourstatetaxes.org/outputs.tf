output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.pya.log_bucket
}

output "docker_push" {
  description = "Display commands to push the Docker image to ECR."
  value = module.pya.docker_push
}

output "repository_arn" {
  description = "AWS Repository Amazon Resource Name (ARN) for ECR"
  value = module.pya.repository_arn
}

output "repository_url" {
  description = "AWS Repository URL for ECR"
  value = module.pya.repository_url
}
