# Variables for AWS Textract Module

variable "lambda_role_name" {
  description = "The name of the Lambda IAM role to attach Textract permissions to"
  type        = string
}

variable "textract_policy_type" {
  description = "Type of Textract access policy to attach (full or read-only)"
  type        = string
  default     = "full"
  validation {
    condition     = contains(["full", "read-only"], var.textract_policy_type)
    error_message = "textract_policy_type must be either 'full' or 'read-only'"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}