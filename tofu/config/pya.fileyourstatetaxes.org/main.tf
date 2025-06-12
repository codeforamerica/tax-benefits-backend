terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "staging.fileyourstatetaxes.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "fyst"
  environment              = "staging"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/fyst/staging"
      tags = {
        source = "waf"
        webacl = "fyst-staging"
        domain = "staging.fileyourstatetaxes.org"
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "fyst"
  environment = "staging"
}

module "waf" {
  source = "../../modules/aptible_waf"

  project              = "fyst"
  environment          = "staging"
  domain               = "fileyourstatetaxes.org"
  log_bucket           = module.logging.bucket_domain_name
  log_group            = module.logging.log_groups["waf"]
  aptible_environment  = "vita-min-staging"
  aptible_app_id       = 17866
  allow_security_scans = false
  secrets_key_arn      = module.secrets.kms_key_arn
}
