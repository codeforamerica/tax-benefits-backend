terraform {
  backend "s3" {
    bucket         = "tax-benefits-staging-pya"
    key            = "staging.prioryearaccess.org"
    region         = "us-east-1"
  }
}


module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "pya"
  environment              = "staging"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/pya/staging"
      tags = {
        source = "waf"
        webacl = "pya-staging"
        domain = "staging.prioryearaccess.org"
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "pya"
  environment = "staging"
}

# module "cloudfront_waf" {
#   source = "github.com/codeforamerica/tofu-modules-aws-cloudfront-waf?ref=1.9.0"
#
#   project     = "pya"
#   environment = "staging"
#   domain      = "staging.prioryearaccess.org"
#   log_bucket  = module.logging.bucket
#   /*  The argument "log_group" is required, but no definition was found. What should this be? */
# }
#

  project     = "pya"
  environment = "staging"
  domain      = "staging.prioryearaccess.org"
  log_bucket  = module.logging.bucket
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"

  project       = "pya"
  project_short = "pya"
  environment   = "staging"
  service       = "web"
  service_short = "web"

  domain          = "staging.prioryearaccess.org"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 3000

  environment_variables = {
    RACK_ENV = "staging"
  }
}

module "workers" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"

  project       = "pya"
  project_short = "pya"
  environment   = "staging"
  service       = "worker"
  service_short = "wrk"

  domain          = "staging.prioryearaccess.org"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 3000

  environment_variables = {
    RACK_ENV = "staging"
  }
}
