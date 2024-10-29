terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "ctc.staging.getyourrefund.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.2.1"

  project                  = "ctc"
  environment              = "staging"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/ctc/staging"
      tags = {
        source = "waf"
        webacl = "ctc-staging"
        domain = "ctc.staging.getyourrefund.org"
      }
    }
  }
}

module "waf" {
  source = "../../modules/aptible_waf"

  project                 = "ctc"
  environment             = "staging"
  domain                  = "getyourrefund.org"
  subdomain               = "ctc.staging"
  log_bucket              = module.logging.bucket_domain_name
  log_group               = module.logging.log_groups["waf"]
  aptible_environment     = "vita-min-staging"
  aptible_app_id          = 17866
  allow_security_scanners = false
}
