terraform {
  backend "s3" {
    bucket         = "gyraffe-production-tfstate"
    key            = "production.gyraffe.getyourrefund.org"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "gyraffe"
  environment = "production"
}

module "gyraffe" {
  source = "../../modules/gyraffe"

  environment     = "production"
  domain          = "production.gyraffe.getyourrefund.org"
  cidr            = "10.0.68.0/22"
  private_subnets = ["10.0.70.0/26", "10.0.70.64/26", "10.0.70.128/26"]
  public_subnets  = ["10.0.68.0/26", "10.0.68.64/26", "10.0.68.128/26"]
  review_app      = "true"
}
