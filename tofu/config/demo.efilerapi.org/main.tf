terraform {
  backend "s3" {
    bucket         = "efiler-api-demo-tfstate"
    key            = "demo.efilerapi.org"
    region         = "us-east-1"
    dynamodb_table = "demo.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "efiler-api"
  environment = "demo"
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "efiler-api"
  environment = "dev"
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  project        = "efiler-api"
  environment    = "dev"
  cidr           = "10.0.48.0/22"
  logging_key_id = module.logging.kms_key_arn

  private_subnets = ["10.0.50.0/26", "10.0.50.64/26", "10.0.50.128/26"]
  public_subnets  = ["10.0.48.0/26", "10.0.48.64/26", "10.0.48.128/26"]
}
