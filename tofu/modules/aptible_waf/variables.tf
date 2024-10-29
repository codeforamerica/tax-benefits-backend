variable "allow_security_scanners" {
  type        = bool
  description = "Allow security scanners to access the site."
  default     = false
}

variable "aptible_environment" {
  type        = string
  description = "Name of the Aptible environment to attach the WAF to."
}

variable "aptible_app_id" {
  type = number
  description = "Id of the Aptible app to attach the WAF to."
}

variable "domain" {
  description = "Domain the WAF is protecting."
  type        = string
}

variable "environment" {
  description = "The environment in which the WAF is being deployed."
  type        = string
  default     = "development"
}

variable "log_bucket" {
  type        = string
  description = "S3 Bucket to send logs to."
}

variable "log_group" {
  type        = string
  description = "CloudWatch log group to send WAF logs to."
}

variable "passive" {
  type        = bool
  description = "Enable passive mode for the WAF, counting all requests rather than blocking."
  default     = false
}

variable "project" {
  type        = string
  description = "Project the WAF is being deployed for."
}

variable "rate_limit_requests" {
  type        = number
  description = "Number of requests allowed in the rate limit window. Minimum of 10, or set to 0 to disable rate limiting."
  default     = 20
}

variable "rate_limit_window" {
  type        = number
  description = "Time window, in seconds, for the rate limit. Options are: 60, 120, 300, 600"
  default     = 60
}

variable "subdomain" {
  type        = string
  description = "Subdomain for the application. Defaults to the environment."
  default     = ""
}
