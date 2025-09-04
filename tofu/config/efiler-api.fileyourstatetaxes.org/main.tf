terraform {
  backend "s3" {
    bucket         = "efiler-api-production-tfstate"
    key            = "production.efiler-api.fileyourstatetaxes.org"
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

  environment         = "production"
  domain              = "production.efiler-api.fileyourstatetaxes.org"
  cidr                = ""
  private_subnets     = []
  public_subnets      = []
}
