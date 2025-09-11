locals {
  static_secrets = {
    "rails_secret_key_base" = {
      description = "secret_key_base for Rails app"
      start_value = jsonencode({
        key = ""
      })
    }
  }

  api_client_secrets = {
    for api_client_name in var.api_client_names : "efiler-api-client-credentials/${api_client_name}" => {
      description = "credentials for ${api_client_name}"
      add_suffix = false
      start_value = jsonencode({
        app_sys_id = ""
        etin = ""
        cert_base64 = ""
        mef_env = ""
        efiler_api_public_key = ""
      })
    }
  }

  static_secret_names = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE        = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
  }

  api_client_secret_names = {
    for api_client_name in var.api_client_names :
      # The key passed here ("etin") is necessary for the policy created to have access to the correct secrets,
      # and we ignore the env variables that it creates. Ideally, there'd be a way to pass a secret ARN without a key
      # and have it only used in policy creation and ignored for environment variables
      api_client_name => "${module.secrets.secrets["efiler-api-client-credentials/${api_client_name}"].secret_arn}:etin"
  }
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project     = "efiler-api"
  environment = var.environment
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  project        = "efiler-api"
  environment    = var.environment
  cidr           = var.cidr
  logging_key_id = module.logging.kms_key_arn

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=2.0.0"

  project     = "efiler-api"
  environment = var.environment

  secrets = merge(local.static_secrets, local.api_client_secrets)
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.6.0"

  project       = "efiler-api"
  project_short = "efiler-api"
  environment   = var.environment
  service       = "web"
  service_short = "web"

  domain          = var.domain
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 8080
  create_endpoint = true
  create_repository   = true
  create_version_parameter = true
  public = false
  enable_execute_command = true
  use_target_group_port_suffix = true

  environment_variables = {
    RACK_ENV = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
  }

  environment_secrets = merge(local.static_secret_names, local.api_client_secret_names)
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.3.1"

  project     = "efiler-api"
  environment = var.environment
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
  environment        = var.environment
  key_pair_name      = "efiler-api-${var.environment}-bastion"
  private_subnet_ids = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}
