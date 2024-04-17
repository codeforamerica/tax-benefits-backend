terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key    = "demo.fileyourstatetaxes.org.tfstate"
    region = "us-east-1"
  }
}

# TODO: Make a logging bucket module to make sure this is properly configured.
#trivy:ignore:avd-aws-0088
#trivy:ignore:avd-aws-0089
#trivy:ignore:avd-aws-0090
#trivy:ignore:avd-aws-0132
module "log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket                   = "fyst-demo-logs"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
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
  log_bucket  = module.log_bucket.s3_bucket_bucket_domain_name
}
