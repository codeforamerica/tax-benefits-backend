terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key    = "demo.mireembolso.org.tfstate"
    region = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=1.1.0"

  project                  = "gyr-es"
  environment              = "demo"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/gyr-es/demo"
      tags = {
        source = "waf"
        webacl = "gyr-es-demo"
        domain = "demo.mireembolso.org"
      }
    }
  }
}

module "waf" {
  source = "../../modules/aptible_waf"

  project                 = "gyr-es"
  environment             = "demo"
  domain                  = "mireembolso.org"
  log_bucket              = module.logging.bucket_domain_name
  log_group               = module.logging.log_groups["waf"]
  aptible_environment     = "vita-min-demo"
  aptible_app_id          = 17865
  allow_security_scanners = false
}
