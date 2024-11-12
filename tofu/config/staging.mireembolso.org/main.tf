terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "staging.mireembolso.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.2.1"

  project                  = "gyr-es"
  environment              = "staging"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/gyr-es/staging"
      tags = {
        source = "waf"
        webacl = "gyr-es-staging"
        domain = "staging.mireembolso.org"
      }
    }
  }
}

module "waf" {
  source = "../../modules/aptible_waf"

  project                 = "gyr-es"
  environment             = "staging"
  domain                  = "mireembolso.org"
  log_bucket              = module.logging.bucket_domain_name
  log_group               = module.logging.log_groups["waf"]
  aptible_environment     = "vita-min-staging"
  aptible_app_id          = 17866
  allow_security_scans = false
}
