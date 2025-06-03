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

module "pya" {
  source = "../../modules/pya"

  environment         = "staging"
  domain              = "staging.pya.fileyourstatetaxes.org"
  cidr                = "10.0.36.0/22"
  private_subnets     = ["10.0.38.0/26", "10.0.38.64/26", "10.0.38.128/26"]
  public_subnets      = ["10.0.36.0/26", "10.0.36.64/26", "10.0.36.128/26"]
}
