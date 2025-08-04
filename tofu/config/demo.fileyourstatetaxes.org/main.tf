terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "demo.fileyourstatetaxes.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "fyst"
  environment              = "demo"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/fyst/demo"
      tags = {
        source = "waf"
        webacl = "fyst-demo"
        domain = "demo.fileyourstatetaxes.org"
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "fyst"
  environment = "demo"
}

module "waf" {
  source = "../../modules/aptible_waf"

  project              = "fyst"
  environment          = "demo"
  domain               = "fileyourstatetaxes.org"
  log_bucket           = module.logging.bucket_domain_name
  log_group            = module.logging.log_groups["waf"]
  aptible_environment  = "vita-min-demo"
  aptible_app_id       = 17865
  allow_security_scans = true
  secrets_key_arn      = module.secrets.kms_key_arn

  security_scan_cidrs = [
    # Detectify
    "52.17.9.21/32",
    "52.17.98.131/32",
    # SecurityMetrics
    "162.211.152.0/24",
    # Tenable
    "34.201.223.128/25",
    "44.192.244.0/24",
    "44.206.3.0/24",
    "54.175.125.192/26",
    "13.59.252.0/25",
    "18.116.198.0/24",
    "3.132.217.0/25",
    "13.56.21.128/25",
    "34.223.64.0/25",
    "35.82.51.128/25",
    "35.86.126.0/24",
    "35.93.174.0/24",
    "44.242.181.128/25"
  ]
}
