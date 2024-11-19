terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "demo.getyourrefund.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.2.1"

  project                  = "gyr"
  environment              = "demo"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/gyr/demo"
      tags = {
        source = "waf"
        webacl = "gyr-demo"
        domain = "demo.getyourrefund.org"
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "gyr"
  environment = "demo"
}

module "waf" {
  source = "../../modules/aptible_waf"

  project              = "gyr"
  environment          = "demo"
  domain               = "getyourrefund.org"
  log_bucket           = module.logging.bucket_domain_name
  log_group            = module.logging.log_groups["waf"]
  aptible_environment  = "vita-min-demo"
  aptible_app_id       = 17865
  allow_gyr_uploads    = true
  allow_security_scans = true
  rate_limit_requests  = 200
  secrets_key_arn      = module.secrets.kms_key_arn
}
