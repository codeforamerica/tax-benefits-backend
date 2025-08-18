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

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "efiler-api"
  environment = "demo"
}

module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "efiler-api"
  environment = "demo"

  secrets = {
  }
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  project        = "efiler-api"
  environment    = "demo"
  cidr           = "10.0.48.0/22"
  logging_key_id = module.logging.kms_key_arn

  private_subnets = ["10.0.50.0/26", "10.0.50.64/26", "10.0.50.128/26"]
  public_subnets  = ["10.0.48.0/26", "10.0.48.64/26", "10.0.48.128/26"]
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.6.0"

  project       = "efiler-api"
  project_short = "efiler-api"
  environment   = "demo"
  service       = "web"
  service_short = "web"

  domain          = "demo.efiler-api.fileyourstatetaxes.org"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 80
  create_endpoint = true
  create_repository   = true
  create_version_parameter = true
  public = false
  enable_execute_command = true
  use_target_group_port_suffix = true

  # This has an ARN specified manually until we decide to make the secrets module work without adding suffices to the secret names
  task_policies = ["arn:aws:iam::669097061340:policy/efiler-api-client-mef-credentials-access"]

  environment_variables = {
    RACK_ENV = "demo"
    DATABASE_HOST = module.database.cluster_endpoint
  }

  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"

    # This has an ARN specified manually until we start using the secrets module for MeF credential secrets (see above)
    SECRET_KEY_BASE = "arn:aws:secretsmanager:us-east-1:669097061340:secret:rails_secret_key_base-h1ygaE:key"
  }
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.3.1"

  project     = "efiler-api"
  environment = "demo"
  service     = "web"
  skip_final_snapshot	= true

  logging_key_arn = module.logging.kms_key_arn
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  ingress_cidrs   = module.vpc.private_subnets_cidr_blocks

  min_capacity = 0
  max_capacity = 10
  cluster_parameters = []
}

module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.0.0"

  project            = "efiler-api"
  environment        = "demo"
  key_pair_name      = "efiler-api-demo-bastion"
  private_subnet_ids = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}
