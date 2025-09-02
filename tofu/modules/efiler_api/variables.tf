variable "environment" {
  description = "The environment in which the e-filer api infrastructure is being deployed."
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
