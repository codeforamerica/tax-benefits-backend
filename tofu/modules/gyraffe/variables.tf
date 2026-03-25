variable "project" {
  type = string
  description = "The name of the project"
  default = "gyraffe"
}

variable "domain" {
  description = "Gyraffe domain"
  type        = string
}

variable "environment" {
  description = "The environment in which the Gyraffe infrastructure is being deployed."
  type        = string
}

variable "cidr" {
  type        = string
  description = "CIDR for vpc"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDRs for private_subnets"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDRs for public_subnets"
}

variable "review_app" {
  type        = string
  description = "whether this is a application for reviewing code changes (staging/heroku/demo)"
  default     = "true"
}

variable "vpc_peers" {
  type = map(object({
    account_id = string
    cidr       = string
    region     = string
    vpc_id     = string
  }))

  description = "List of VPC peering connections."
  default     = {}
}

variable "allow_security_scans" {
  type        = bool
  description = "Allow security scanners to bypass the WAF."
  default     = false
}

variable "security_scan_cidrs" {
  type        = list(string)
  description = "CIDRs for security scanners to allow through the WAF. Defaults to Tenable One CIDRs."
  default = [
    # Tenable One
    "34.201.223.128/25",
    "44.192.244.0/24",
    "44.206.3.0/24",
    "54.175.125.192/26",
    "13.59.252.0/25",
    "18.116.198.0/24",
    "3.132.217.0/25"
  ]
}

variable "rate_limit_requests" {
  type        = number
  description = "Number of requests allowed in the rate limit window. Minimum of 10, or set to 0 to disable rate limiting."
  default     = 100
}

variable "rate_limit_window" {
  type        = number
  description = "Time window, in seconds, for the rate limit. Options are: 60, 120, 300, 600"
  default     = 60
}

variable "passive_waf" {
  type        = bool
  description = "Enable passive mode for the WAF, counting all requests rather than blocking."
  default     = false
}
