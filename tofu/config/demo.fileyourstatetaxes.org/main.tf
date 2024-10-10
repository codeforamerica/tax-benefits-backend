terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key    = "demo.fileyourstatetaxes.org.tfstate"
    region = "us-east-1"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules/aws/logging"

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

module "waf" {
  source = "../../modules/aptible_waf"

  project                 = "fyst"
  environment             = "demo"
  domain                  = "fileyourstatetaxes.org"
  log_bucket              = module.logging.bucket_domain_name
  log_group               = module.logging.log_groups["waf"]
  aptible_environment     = "vita-min-demo"
  allow_security_scanners = true
}
