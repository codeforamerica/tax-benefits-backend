output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.logging.bucket
}

output "athena_policy_arn" {
  description = "The ARN of the IAM policy granting Athena access for GYR logs."
  value       = module.athena.athena_policy_arn
}
