variable "database_username" {
  type        = string
  description = "Username for the database IAM user."
}

variable "data_science_database_user" {
  type        = string
  description = "Username for the data science read-only database user."
  default     = null
}

variable "data_science_databases" {
  type        = list(string)
  description = "List of databases to grant data science read-only access to."
  default     = []
}
