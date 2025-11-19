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
