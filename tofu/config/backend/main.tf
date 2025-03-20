terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "tax-benefits"
  environment = "prod"
}
