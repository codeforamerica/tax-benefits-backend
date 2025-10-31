variable "domain" {
  description = "PYA domain"
  type        = string
}

variable "environment" {
  description = "The environment in which the PYA infrastructure is being deployed."
  type        = string
  default     = "development"
}

variable "cidr" {
  type        = string
  description = "CIDR for vpc"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDRs for private_subnets"
}

variable "project" {
  type = string
  description = "The name of the project"
  default = "pya"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDRs for public_subnets"
}

variable "state_version_expiration" {
  type        = number
  description = "Age (in days) before non-current versions of the state file are expired."
  default     = 30
}

variable "review_app" {
  type        = string
  description = "whether this is a application for reviewing code changes (staging/heroku/demo)"
  default     = "true"
}
