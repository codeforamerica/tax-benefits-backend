terraform {
  backend "s3" {
    bucket         = "workflow-workbench-staging-tfstate"
    key            = "staging.workflow-workbench.fileyourstatetaxes.org"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "workflow-workbench"
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

module "workflow-workbench" {
  source = "../../modules/workflow-workbench"

  environment = "staging"
  domain      = "staging.workflow-workbench.fileyourstatetaxes.org"
  
  # Build artifacts - these will be provided by CI/CD
  lambda_package_path = var.lambda_package_path
  ui_dist_path        = var.ui_dist_path
  
  # Optional: Use existing VPC if available
  # vpc_id             = module.vpc.vpc_id
  # private_subnet_ids = module.vpc.private_subnet_ids
  # public_subnet_ids  = module.vpc.public_subnet_ids
  
  # Optional: Use existing KMS key
  # kms_key_arn = module.backend.kms_key_arn
  
  # WAF enabled for staging
  enable_waf = true
  
  # CloudWatch logs retention
  log_retention_days = 30
  
  # CORS configuration
  allowed_origins = [
    "https://staging.workflow-workbench.fileyourstatetaxes.org",
    "http://localhost:1234"  # For local development
  ]
  
  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
    Repository  = "workflow-workbench"
  }
}
