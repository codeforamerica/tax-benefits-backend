variable "workgroup_name" {
  description = "The name of the Athena workgroup."
  type        = string
}

variable "database_name" {
  description = "The name of the Athena database."
  type        = string
}

variable "result_bucket_name" {
  description = "The name of the S3 bucket to store Athena results."
  type        = string
}

variable "result_retention_days" {
  description = "The number of days to keep Athena results in the S3 bucket."
  type        = number
  default     = 7
}

variable "source_bucket_arns" {
  description = "A list of S3 bucket ARNs that Athena will query data from."
  type        = list(string)
  default     = []
}
