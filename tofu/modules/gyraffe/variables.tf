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
