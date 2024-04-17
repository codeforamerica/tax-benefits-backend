terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key    = "demo.fileyourstatetaxes.org.tfstate"
    region = "us-east-1"
  }
}

# TODO: Make a logging bucket module to make sure this is properly configured.
module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket                   = "fyst-demo-logs"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}

module "waf" {
  source = "github.com/codeforamerica/tofu-modules/aws/cloudfront_waf"

  project     = "fyst"
  environment = "demo"
  domain      = "fileyourstatetaxes.org"
  log_bucket  = module.log_bucket.s3_bucket_bucket_domain_name
}
