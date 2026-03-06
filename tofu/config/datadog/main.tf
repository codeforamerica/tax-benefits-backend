terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "datadog.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

locals {
  slack_account_name = "cfastaff"
}

module "datadog" {
  source = "github.com/codeforamerica/tofu-modules-datadog-waf?ref=1.1.0"

  # Default to the production ACLs.
  default_webacls = [
    "ctc-production",
    "gyr-production",
    "gyr-es-production",
    "fyst-production",
    "pya-production"
  ]
}

resource "datadog_integration_slack_channel" "security_alerts" {
  account_name = local.slack_account_name
  channel_name = "#security-alerts"

  display {
    message  = true
    notified = true
    snapshot = false
    tags     = true
  }
}

resource "datadog_integration_slack_channel" "tax_alerts" {
  account_name = local.slack_account_name
  channel_name = "#tax-alerts"

  display {
    message  = true
    notified = true
    snapshot = false
    tags     = true
  }
}

module "sensitive_data_scanner" {
  source = "github.com/codeforamerica/tofu-modules-datadog-sensitive-data-scanner?ref=1.2.0"

  group_name   = "Production Environment Scanning"
  filter_query = "env:prod"
  product_list = ["logs", "apm"]
  enable_monitors = true
  notification_targets = ["@slack-${local.slack_account_name}-security-alerts", "@slack-${local.slack_account_name}-tax-alerts"]
}
