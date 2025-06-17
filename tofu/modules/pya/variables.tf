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

variable "public_subnets" {
  type        = list(string)
  description = "CIDRs for public_subnets"
}

variable "state_version_expiration" {
  type        = number
  description = "Age (in days) before non-current versions of the state file are expired."
  default     = 30
}

variable "kms_key_id" {
  description = "ARN or Id of the AWS KMS key to be used to encrypt the secret values in the versions stored in this secret. If you need to reference a CMK in a different account, you can use only the key ARN. If you don't specify this value, then Secrets Manager defaults to using the AWS account's default KMS key (the one named `aws/secretsmanager`"
  type        = string
  default     = null
}

variable "bucket_arn" {
  description = "ARN or ID of the AWS S3 bucket storing tfstate"
  type = string
}
