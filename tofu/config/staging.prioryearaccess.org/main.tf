terraform {
  backend "s3" {
    bucket         = "pya-staging-tfstate"
    key            = "staging.prioryearaccess.org"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "pya"
  environment = "staging"
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
        domain = "staging.pya.fileyourstatetaxes.org"
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
#   domain      = "staging.pya.fileyourstatetaxes.org"
#   log_bucket  = module.logging.bucket
#   /*  The argument "log_group" is required, but no definition was found. What should this be? */
# }
#


# module "vpc" {
#   source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"
#
#   project        = "pya"
#   environment    = "staging"
#   cidr           = "10.0.36.0/22"
#   logging_key_id = module.logging.kms_key_arn
#
#   private_subnets = ["10.0.38.0/26", "10.0.38.64/26", "10.0.38.128/26"]
#   public_subnets  = ["10.0.36.0/26", "10.0.36.64/26", "10.0.36.128/26"]
# }

# module "web" {
#   source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"
#
#   project       = "pya"
#   project_short = "pya"
#   environment   = "staging"
#   service       = "web"
#   service_short = "web"
#
#   domain          = "staging.pya.fileyourstatetaxes.org"
#   vpc_id          = module.vpc.vpc_id
#   private_subnets = module.vpc.private_subnets
#   public_subnets  = module.vpc.public_subnets
#   logging_key_id  = module.logging.kms_key_arn
#   container_port  = 3000
#   create_endpoint	= true
#   create_repository	= true
#   create_version_parameter = true
#   public = true
#
#   environment_variables = {
#     RACK_ENV = "staging"
#   }
# }
#
# module "workers" {
#   source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"
#
#   project       = "pya"
#   project_short = "pya"
#   environment   = "staging"
#   service       = "worker"
#   service_short = "wrk"
#
#   vpc_id          = module.vpc.vpc_id
#   private_subnets = module.vpc.private_subnets
#   public_subnets  = module.vpc.public_subnets
#   logging_key_id  = module.logging.kms_key_arn
#   container_port  = 3000
#   version_parameter = module.web.version_parameter
#   image_url = module.web.repository_url
#   create_endpoint = false
#
#   environment_variables = {
#     RACK_ENV = "staging"
#   }
# }
#
# module "database" {
#   source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=log-exports"
#
#   project     = "pya"
#   environment = "staging"
#   service     = "web"
#
#   logging_key_arn = module.logging.kms_key_arn
#   secrets_key_arn = module.secrets.kms_key_arn
#   vpc_id          = module.vpc.vpc_id
#   subnets         = module.vpc.private_subnets
#   ingress_cidrs   = module.vpc.private_subnets_cidr_blocks
#   iam_authentication = false
#
#   min_capacity = 2
#   max_capacity = 32
#   cluster_parameters = []
# }
