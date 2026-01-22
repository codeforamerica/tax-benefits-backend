locals {
  datadog_lambda = [
    for lambda in data.aws_lambda_functions.all.function_names :
    lambda if length(regexall("^DatadogIntegration-ForwarderStack-", lambda)) > 0
  ]

  database_user = var.database_user == null ? "pya-${var.environment}-rds" : var.database_user
}
