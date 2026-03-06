terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "datadog.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
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
  account_name = "cfastaff"
  channel_name = "#security-alerts"

  display {
    message  = true
    notified = true
    snapshot = false
    tags     = true
  }
}

module "sensitive_data_scanner" {
  source = "github.com/codeforamerica/tofu-modules-datadog-sensitive-data-scanner?ref=rd/monitors"

  group_name   = "Production Environment Scanning"
  filter_query = "env:prod"
  product_list = ["logs", "apm"]
  enable_monitors = true
  notification_targets = ["@slack-cfastaff-security-alerts"]
}
