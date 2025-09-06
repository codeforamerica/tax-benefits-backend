variable "project" {
  description = "Project name"
  type        = string
  default     = "workflow-workbench"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
}

variable "domain" {
  description = "Domain name for the application"
  type        = string
}

variable "lambda_package_path" {
  description = "Path to the Lambda deployment package ZIP file"
  type        = string
}

variable "ui_dist_path" {
  description = "Path to the UI distribution files directory"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Lambda and database resources"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (if not provided, a new key will be created)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "enable_waf" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access the application"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "textract_form_adapters_env_var_mapping" {
  type = map(string)
  default = {
    DD214_ADAPTER               = "src.forms.dd214"
    TEN_NINETY_NINE_NEC_ADAPTER = "src.forms.ten_ninety_nine_nec"
    W2_ADAPTER                  = "src.forms.w2"
  }
}

variable "enable_ephemeral" {
  description = "Enable ephemeral environment features (for PR previews)"
  type        = bool
  default     = false
}

variable "ephemeral_suffix" {
  description = "Suffix for ephemeral environment resources (e.g., pr-123)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain (required if domain is set)"
  type        = string
  default     = ""
}

variable "api_key" {
  description = "API key for API Gateway (optional)"
  type        = string
  default     = ""
}

variable "allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "allowed_countries" {
  description = "List of allowed countries for CloudFront geo-restriction"
  type        = list(string)
  default     = []
}