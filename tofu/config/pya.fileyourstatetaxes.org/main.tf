terraform {
  backend "s3" {
    bucket         = "pya-production-tfstate"
    key            = "pya.fileyourstatetaxes.org"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "pya"
  environment = "production"
}

module "pya" {
  source = "../../modules/pya"

  providers = {
    aws.backup = aws.backup
  }

  environment     = "production"
  domain          = "pya.fileyourstatetaxes.org"
  cidr            = "10.0.44.0/22"
  private_subnets = ["10.0.46.0/26", "10.0.46.64/26", "10.0.46.128/26"]
  public_subnets  = ["10.0.44.0/26", "10.0.44.64/26", "10.0.44.128/26"]
  review_app      = "false"

  web_cpu = 1024
  web_memory = 8192
}
