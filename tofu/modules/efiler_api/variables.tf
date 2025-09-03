variable "domain" {
  description = "Efiler API domain"
  type        = string
}

variable "environment" {
  description = "The environment in which the e-filer api infrastructure is being deployed."
  type        = string
}

variable "cidr" {
  description = "CIDR for vpc"
  type        = string
}

variable "private_subnets" {
  description = "CIDRs for private_subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDRs for public_subnets"
  type        = list(string)
}
