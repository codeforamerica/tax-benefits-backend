terraform {
  backend "s3" {
    bucket         = "pya-staging-tfstate"
    key            = "staging.pya.fileyourstatetaxes.org"
    region         = "us-east-1"
    dynamodb_table = "staging.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "pya"
  environment = "staging"
}

module "pya" {
  source = "../../modules/pya"

  providers = {
    aws.backup = aws.backup
  }
  environment     = "staging"
  domain          = "staging.pya.fileyourstatetaxes.org"
  cidr            = "10.0.36.0/22"
  private_subnets = ["10.0.38.0/26", "10.0.38.64/26", "10.0.38.128/26"]
  public_subnets  = ["10.0.36.0/26", "10.0.36.64/26", "10.0.36.128/26"]
  review_app      = "true"
  database_user   = "pya-staging-rds"
  allow_security_scans = true
}
