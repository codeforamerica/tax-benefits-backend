terraform {
  backend "s3" {
    bucket         = "efiler-api-production-tfstate"
    key            = "efiler-api.fileyourstatetaxes.org"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "efiler-api"
  environment = "production"
}

module "efiler_api" {
  source = "../../modules/efiler_api"

  environment     = "production"
  domain          = "efiler-api.fileyourstatetaxes.org"
  cidr            = "10.0.60.0/22"
  private_subnets = ["10.0.62.0/26", "10.0.62.64/26", "10.0.62.128/26"]
  public_subnets  = ["10.0.60.0/26", "10.0.60.64/26", "10.0.60.128/26"]
}
