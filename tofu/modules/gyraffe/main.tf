module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "gyraffe"
  environment              = var.environment
  cloudwatch_log_retention = 30
  log_groups = {
    "waf" = {
      name = "aws-waf-logs-cfa/gyraffe/${var.environment}"
      tags = {
        source = "waf"
        webacl = "gyraffe-${var.environment}"
        domain = var.domain
      }
    }
  }
}

# We don't need to create any secrets here, but we need the infrastructure for
# other modules to utilize.
module "secrets" {
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=2.0.0"

  project     = "gyraffe"
  environment = var.environment

  secrets = {
    "rails_secret_key_base" = {
      description = "secret_key_base for Rails app"
    },
    "twilio_account_sid" = {
      description = "account sid for twilio"
    },
    "twilio_auth_token" = {
      description = "auth token for twilio"
    },
    "twilio_messaging_service_sid" = {
      description = "messaging service sid for twilio"
    },
    "mailgun_api_key" = {
      description = "API key for Mailgun"
    },
    "mailgun_domain" = {
      description = "Domain used with Mailgun"
    },
    "mailgun_basic_auth_name" = {
      description = "Basic auth username for Mailgun"
    },
    "mailgun_basic_auth_password" = {
      description = "Basic auth password for Mailgun"
    }
  }
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.2"

  project        = "gyraffe"
  environment    = var.environment
  cidr           = var.cidr
  logging_key_id = module.logging.kms_key_arn

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.6.1"

  project       = "gyraffe"
  project_short = "gyraffe"
  environment   = var.environment
  service       = "web"
  service_short = "web"

  domain                   = var.domain
  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
  public_subnets           = module.vpc.public_subnets
  logging_key_id           = module.logging.kms_key_arn
  container_port           = 8080
  create_endpoint          = true
  create_repository        = true
  create_version_parameter = true
  public                   = true
  health_check_path        = "/up"
  enable_execute_command   = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RACK_ENV          = var.environment
    DATABASE_HOST     = module.database.cluster_endpoint
    REVIEW_APP        = var.review_app
    SCHEMA_S3_BUCKET  = module.schemas.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD           = "${module.database.secret_arn}:password"
    DATABASE_USER               = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE             = module.secrets.secrets["rails_secret_key_base"].secret_arn
    TWILIO_ACCOUNT_SID          = module.secrets.secrets["twilio_account_sid"].secret_arn
    TWILIO_AUTH_TOKEN           = module.secrets.secrets["twilio_auth_token"].secret_arn
    TWILIO_MESSAGING_SERVICE    = module.secrets.secrets["twilio_messaging_service_sid"].secret_arn
    MAILGUN_API_KEY             = module.secrets.secrets["mailgun_api_key"].secret_arn
    MAILGUN_DOMAIN              = module.secrets.secrets["mailgun_domain"].secret_arn
    MAILGUN_BASIC_AUTH_NAME     = module.secrets.secrets["mailgun_basic_auth_name"].secret_arn
    MAILGUN_BASIC_AUTH_PASSWORD = module.secrets.secrets["mailgun_basic_auth_password"].secret_arn
  }
}

module "workers" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.6.1"

  project       = "gyraffe"
  project_short = "gyraffe"
  environment   = var.environment
  service       = "worker"
  service_short = "worker"

  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  public_subnets         = module.vpc.public_subnets
  logging_key_id         = module.logging.kms_key_arn
  container_port         = 8080
  version_parameter      = module.web.version_parameter
  image_url              = module.web.repository_url
  create_endpoint        = false
  create_repository      = false
  enable_execute_command = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RACK_ENV          = var.environment
    DATABASE_HOST     = module.database.cluster_endpoint
    REVIEW_APP        = var.review_app
    SCHEMA_S3_BUCKET  = module.schemas.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD           = "${module.database.secret_arn}:password"
    DATABASE_USER               = "${module.database.secret_arn}:username"
    SECRET_KEY_BASE             = module.secrets.secrets["rails_secret_key_base"].secret_arn
    TWILIO_ACCOUNT_SID          = module.secrets.secrets["twilio_account_sid"].secret_arn
    TWILIO_AUTH_TOKEN           = module.secrets.secrets["twilio_auth_token"].secret_arn
    TWILIO_MESSAGING_SERVICE    = module.secrets.secrets["twilio_messaging_service_sid"].secret_arn
    MAILGUN_API_KEY             = module.secrets.secrets["mailgun_api_key"].secret_arn
    MAILGUN_DOMAIN              = module.secrets.secrets["mailgun_domain"].secret_arn
    MAILGUN_BASIC_AUTH_NAME     = module.secrets.secrets["mailgun_basic_auth_name"].secret_arn
    MAILGUN_BASIC_AUTH_PASSWORD = module.secrets.secrets["mailgun_basic_auth_password"].secret_arn
  }

  container_command = ["bin/jobs"]
  repository_arn    = module.web.repository_arn
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.3.1"

  project             = "gyraffe"
  environment         = var.environment
  service             = "web"
  skip_final_snapshot = true

  logging_key_arn    = module.logging.kms_key_arn
  secrets_key_arn    = module.secrets.kms_key_arn
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
  ingress_cidrs      = module.vpc.private_subnets_cidr_blocks
  iam_authentication = true
  enable_data_api    = true
  password_rotation_frequency = 90

  min_capacity       = 0
  max_capacity       = 10
  cluster_parameters = []
}

locals {
  aws_logs_path = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
}

data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "submission_bundles" {
  description             = "OpenTofu submission_bundles S3 encryption key for gyraffe ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : module.submission_bundles.bucket,
    environment : var.environment
  })
}

resource "aws_kms_key" "docs" {
  description             = "OpenTofu docs S3 encryption key for gyraffe ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : module.docs.bucket,
    environment : var.environment
  })
}

resource "aws_kms_key" "schemas" {
  description             = "OpenTofu docs S3 encryption key for gyraffe ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : module.schemas.bucket,
    environment : var.environment
  })
}

# IAM policy for ECS tasks to access S3
resource "aws_iam_policy" "ecs_s3_access" {
  name = "gyraffe-${var.environment}-ecs-s3-access"

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
          module.submission_bundles.arn,
          "${module.submission_bundles.arn}/*",
          aws_kms_key.submission_bundles.arn,
          module.docs.arn,
          "${module.docs.arn}/*",
          aws_kms_key.docs.arn,
          module.schemas.arn,
          "${module.schemas.arn}/*",
          aws_kms_key.schemas.arn,
        ]
      }
    ]
  })
}

module "bastion" {
  source = "github.com/codeforamerica/tofu-modules-aws-ssm-bastion?ref=1.1.0"

  project            = "gyraffe"
  environment        = var.environment
  key_pair_name      = "gyraffe-${var.environment}-bastion"
  private_subnet_ids = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
  instance_profile   = null
}

resource "aws_cloudwatch_log_subscription_filter" "datadog" {
  for_each = length(local.datadog_lambda) > 0 ? toset(["web", "worker"]) : toset([])

  name            = "datadog"
  log_group_name  = "/aws/ecs/gyraffe/${var.environment}/${each.key}"
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.datadog["this"].arn
}
