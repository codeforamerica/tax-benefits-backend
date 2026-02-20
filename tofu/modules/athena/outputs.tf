output "workgroup_name" {
  description = "The name of the Athena workgroup."
  value       = aws_athena_workgroup.this.name
}

output "database_name" {
  description = "The name of the Athena database."
  value       = aws_athena_database.this.id
}

output "result_bucket" {
  description = "The name of the S3 bucket storing Athena results."
  value       = aws_s3_bucket.athena_results.bucket
}

output "athena_policy_arn" {
  description = "The ARN of the IAM policy granting Athena access."
  value       = aws_iam_policy.athena_access.arn
}
