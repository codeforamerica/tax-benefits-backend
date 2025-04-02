output "log_bucket" {
  description = "The Amazon S3 bucket to store log files."
  value       = module.logging.bucket
}
