locals {
  logs_path = "/AWSLogs/${data.aws_caller_identity.current.account_id}"
  tags      = merge(var.tags, { use = "log-archive" })
}
