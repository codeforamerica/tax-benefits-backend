terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key    = "demo.fileyourstatetaxes.org.tfstate"
    region = "us-east-1"
  }
}

module "logging" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/logging"

  project                  = "fyst"
  environment              = "demo"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/fyst/demo"
      tags = { source = "waf" }
    }
  }
}

# TODO: Make sure we have access logging configured.
#trivy:ignore:avd-aws-0010
module "waf" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/cloudfront_waf"

  project     = "fyst"
  environment = "demo"
  domain      = "fileyourstatetaxes.org"
  log_bucket  = module.logging.bucket_domain_name
  log_group   = module.logging.log_groups["waf"]
}
