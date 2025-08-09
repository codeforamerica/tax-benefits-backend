# Outputs for AWS Textract Module

output "textract_policy_arn" {
  description = "The ARN of the attached Textract policy"
  value       = var.textract_policy_type == "full" ? data.aws_iam_policy.textract_full_access[0].arn : data.aws_iam_policy.textract_read_only[0].arn
}

output "policy_attachment_id" {
  description = "The unique ID for the policy attachment"
  value       = aws_iam_role_policy_attachment.textract_permission.id
}

output "policy_type" {
  description = "The type of Textract policy attached (full or read-only)"
  value       = var.textract_policy_type
}