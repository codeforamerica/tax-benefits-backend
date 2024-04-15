terraform {
  backend "s3" {
    bucket = "tax-benefits-prod-tfstate"
    key = "backend.tfstate"
    region = "us-east-1"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules/aws/backend"

  project = "tax-benefits"
  environment = "prod"
}
