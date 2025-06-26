module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "pya"
  environment              = var.environment
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/pya/${var.environment}"
      tags = {
        source = "waf"
        webacl = "pya-${var.environment}"
        domain = var.domain
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=1.0.0"

  project     = "pya"
  environment = var.environment

  secrets = {
    "rails_secret_key_base" = {
      description = "secret_key_base for Rails app"
      start_value = jsonencode({
        key = ""
      })
    }
  }
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.1"

  project        = "pya"
  environment    = var.environment
  cidr           = var.cidr
  logging_key_id = module.logging.kms_key_arn

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"

  project       = "pya"
  project_short = "pya"
  environment   = var.environment
  service       = "web"
  service_short = "web"

  domain          = var.domain
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 3000
  create_endpoint	= true
  create_repository	= true
  create_version_parameter = true
  public = true
  health_check_path = "/up"

  environment_variables = {
    RACK_ENV = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET = aws_s3_bucket.submission_pdfs.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE        = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
  }
}

module "workers" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.2.0"

  project       = "pya"
  project_short = "pya"
  environment   = var.environment
  service       = "worker"
  service_short = "wrk"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  logging_key_id  = module.logging.kms_key_arn
  container_port  = 3000
  version_parameter = module.web.version_parameter
  image_url = module.web.repository_url
  create_endpoint = false

  environment_variables = {
    RACK_ENV = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET = aws_s3_bucket.submission_pdfs.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE        = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
  }
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=log-exports"

  project     = "pya"
  environment = var.environment
  service     = "web"
  skip_final_snapshot	= true

  logging_key_arn = module.logging.kms_key_arn
  secrets_key_arn = module.secrets.kms_key_arn
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  ingress_cidrs   = module.vpc.private_subnets_cidr_blocks
  iam_authentication = false

  min_capacity = 2
  max_capacity = 32
  cluster_parameters = []
}

locals {
  aws_logs_path = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
}

data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "submission_pdfs" {
  description             = "OpenTofu submission_pdfs S3 encryption key for pya ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : aws_s3_bucket.submission_pdfs.bucket
  })
}

