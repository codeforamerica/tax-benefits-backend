terraform {
  backend "s3" {
    bucket         = "efiler-api-demo-tfstate"
    key            = "demo.efiler-api.fileyourstatetaxes.org"
    region         = "us-east-1"
    dynamodb_table = "demo.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "efiler-api"
  environment = "demo"
}

module "efiler_api" {
  source = "../../modules/efiler_api"

  environment         = "demo"
  domain              = "demo.efiler-api.fileyourstatetaxes.org"
  cidr                = "10.0.48.0/22"
  private_subnets     = ["10.0.50.0/26", "10.0.50.64/26", "10.0.50.128/26"]
  public_subnets      = ["10.0.48.0/26", "10.0.48.64/26", "10.0.48.128/26"]
  api_client_names    = ["efiler_api_test_client", "efiler_api_test_client_two"]
}
