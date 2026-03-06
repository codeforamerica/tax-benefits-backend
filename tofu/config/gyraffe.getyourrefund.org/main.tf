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
  domain          = "gyraffe.getyourrefund.org"
  cidr            = "10.0.92.0/22"
  private_subnets = ["10.0.94.0/26", "10.0.94.64/26", "10.0.94.128/26"]
  public_subnets  = ["10.0.92.0/26", "10.0.92.64/26", "10.0.92.128/26"]
  review_app      = "false"

  vpc_peers = {
    data_science_aptible = {
      account_id = "916150859591",
      vpc_id     = "vpc-01b5eaea8a0322a4e",
      region     = "us-east-1",
      cidr       = "10.51.0.0/16"
    }
  }
}
