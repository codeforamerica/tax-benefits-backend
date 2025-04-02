terraform {
  backend "s3" {
    bucket         = "tax-benefits-prod-tfstate"
    key            = "demo.getyourrefund.org.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod.tfstate"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "gyr"
  environment              = "demo"
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/gyr/demo"
      tags = {
        source = "waf"
        webacl = "gyr-demo"
        domain = "demo.getyourrefund.org"
      }
    }
  }
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  project        = "gyr"
  environment    = "demo"
  cidr           = "10.0.32.0/22"
  logging_key_id = module.logging.kms_key_arn

  private_subnets = ["10.0.34.0/26", "10.0.34.64/26", "10.0.34.128/26"]
  public_subnets  = ["10.0.32.0/26", "10.0.32.64/26", "10.0.32.128/26"]

  peers = {
    aptible = {
      account_id = "916150859591",
      vpc_id     = "vpc-08bd7f3e997318d6b",
      region     = "us-east-1",
      cidr       = "10.210.0.0/16"
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "gyr"
  environment = "demo"
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=instance-count"

  project     = "gyr"
  environment = "demo"

  logging_key_arn = module.logging.kms_key_arn
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  ingress_cidrs   = concat(module.vpc.private_subnets_cidr_blocks, ["10.210.0.0/16"])
  instances       = 1
  backup_retention_period = 7

  min_capacity      = 2
  max_capacity      = 10
  apply_immediately = true
  enable_data_api   = true
  force_delete      = true

}

module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.0.0"

  project                 = "gyr"
  environment             = "demo"
  private_subnet_ids      = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
  kms_key_recovery_period = 7
}

module "waf" {
  source = "../../modules/aptible_waf"

  project              = "gyr"
  environment          = "demo"
  domain               = "getyourrefund.org"
  log_bucket           = module.logging.bucket_domain_name
  log_group            = module.logging.log_groups["waf"]
  aptible_environment  = "vita-min-demo"
  aptible_app_id       = 17865
  allow_gyr_uploads    = true
  allow_security_scans = true
  rate_limit_requests  = 200
  secrets_key_arn      = module.secrets.kms_key_arn
}
