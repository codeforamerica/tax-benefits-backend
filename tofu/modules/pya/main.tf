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
    },
    "ssn_hashing_key" = {
      description = "Key for encrypting SSN for archived intakes"
      start_value = jsonencode({
        key = ""
      })
    },
      "twilio_account_sid" = {
      description = "account sid for twilio"
      start_value = jsonencode({
        key = ""
      })
    },
    "twilio_auth_token" = {
      description = "auth token for twilio"
      start_value = jsonencode({
        key = ""
       })
     },
    "twilio_messaging_service_sid" = {
      description = "auth token for twilio"
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
  enable_execute_command = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RACK_ENV = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET = aws_s3_bucket.submission_pdfs.bucket
    REVIEW_APP = var.review_app
  }
  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE        = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
    SSN_HASHING_KEY        = "${module.secrets.secrets["ssn_hashing_key"].secret_arn}:key"
    TWILIO_ACCOUNT_SID     = "${module.secrets.secrets["twilio_account_sid"].secret_arn}:key"
    TWILIO_AUTH_TOKEN      = "${module.secrets.secrets["twilio_auth_token"].secret_arn}:key"
    TWILIO_MESSAGING_SERVICE = "${module.secrets.secrets["twilio_messaging_service_sid"].secret_arn}:key"
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
  enable_execute_command = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RACK_ENV = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET = aws_s3_bucket.submission_pdfs.bucket
    REVIEW_APP = var.review_app
  }
  environment_secrets = {
    DATABASE_PASSWORD      = "${module.database.secret_arn}:password"
    DATABASE_USER          = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE        = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
    SSN_HASHING_KEY        = "${module.secrets.secrets["ssn_hashing_key"].secret_arn}:key"
    TWILIO_ACCOUNT_SID     = "${module.secrets.secrets["twilio_account_sid"].secret_arn}:key"
    TWILIO_AUTH_TOKEN      = "${module.secrets.secrets["twilio_auth_token"].secret_arn}:key"
    TWILIO_MESSAGING_SERVICE = "${module.secrets.secrets["twilio_messaging_service_sid"].secret_arn}:key"
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
  enable_data_api = true

  min_capacity = 0
  max_capacity = 10
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
    bucket_arn : aws_s3_bucket.submission_pdfs.bucket,
    environment: var.environment
  })
}

# IAM policy for ECS tasks to access S3
resource "aws_iam_policy" "ecs_s3_access" {
  name = "pya-${var.environment}-ecs-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = [
          aws_s3_bucket.submission_pdfs.arn,
          "${aws_s3_bucket.submission_pdfs.arn}/*",
          aws_kms_key.submission_pdfs.arn
        ]
      }
    ]
  })
}

module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.0.0"

  project            = "pya"
  environment        = var.environment
  key_pair_name      = "pya-${var.environment}-bastion"
  private_subnet_ids = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}
