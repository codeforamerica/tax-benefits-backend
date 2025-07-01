variable "api_gateway_name" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "path_part" {
  type = string
}

variable "resource_parent_id" {
  type = string
}

variable "lambda_execution_role" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "lambda_arch" {
  type    = string
  default = "arm64"
}

# name = lambda name
# handler_file_path = path to the file that contains the code
# handler_package = handler class
# http_method = GET, POST, etc
variable "handler_method_mapping" {
  type = list(map(string))
}

variable "environment_variables" {
  type      = map(string)
  nullable  = true
  sensitive = true
}

variable "authorizer" {
  type     = string
  nullable = true
  default  = null
}
