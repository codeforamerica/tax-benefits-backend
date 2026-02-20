variable "bucket_name" {
  type        = string
  description = <<-EOT
    Name of the S3 bucket to create for log archiving. Must be globally unique.
    EOT
}

variable "datadog_role_name" {
  type        = string
  description = <<-EOT
    Name of the Datadog role that will be granted access to the KMS key.
    EOT
  default     = "DatadogIntegrationRole"
}

variable "key_recovery_period" {
  type        = number
  description = <<-EOT
    Number of days to recover the created KMS key after deletion. Must be
    between `7` and `30`.
    EOT
  default     = 30

  validation {
    condition     = var.key_recovery_period > 6 && var.key_recovery_period < 31
    error_message = "Key recovery period must be between 7 and 30."
  }
}

variable "logging_bucket" {
  type        = string
  description = "S3 bucket to send access logs to."
}

variable "retention_period" {
  type        = number
  description = <<-EOT
    Number of days to retain logs in the archive. Must be between `1` and `3653`
    (10 years). Defaults to `1095` (3 years).
    EOT
  default     = 1095

  validation {
    condition     = var.retention_period > 0 && var.retention_period < 3654
    error_message = "Retention period must be between 1 and 3653."
  }
}

variable "tags" {
  type        = map(string)
  description = "Optional tags to be applied to all resources."
  default     = {}
}
