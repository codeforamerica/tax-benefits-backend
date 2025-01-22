terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "www.fileyourstatetaxes.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.2.1"

  project                  = "fyst"
  environment              = "production"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/fyst/production"
      tags = {
        source = "waf"
        webacl = "fyst-production"
        domain = "www.fileyourstatetaxes.org"
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "fyst"
  environment = "production"
}

module "waf" {
  source = "../../modules/aptible_waf"

  project              = "fyst"
  environment          = "production"
  domain               = "fileyourstatetaxes.org"
  subdomain            = "www"
  log_bucket           = module.logging.bucket_domain_name
  log_group            = module.logging.log_groups["waf"]
  aptible_environment  = "vita-min-prod"
  aptible_app_id       = 17832
  allow_security_scans = true
  secrets_key_arn      = module.secrets.kms_key_arn
  passive              = false
}
