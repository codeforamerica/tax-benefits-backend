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
    "sentry_dsn" = {
      description = "dsn for sentry integration"
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
      description = "messaging service sid for twilio"
      start_value = jsonencode({
        key = ""
      })
    },
    "mailgun_api_key" = {
      description = "API key for Mailgun"
      start_value = jsonencode({
        key = ""
      })
    },
    "mailgun_domain" = {
      description = "Domain used with Mailgun"
      start_value = jsonencode({
        key = ""
      })
    },
    "mailgun_basic_auth_name" = {
      description = "Basic auth username for Mailgun"
      start_value = jsonencode({
        key = ""
      })
    },
    "mailgun_basic_auth_password" = {
      description = "Basic auth password for Mailgun"
      start_value = jsonencode({
        key = ""
      })
    },
    "intercom_app_id" = {
      description = "Application id for intercom"
      start_value = jsonencode({
        key = ""
      })
    },
    "intercom_secure_mode_secret_key" = {
      description = "secret key for intercom secure mode"
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
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.9.0"

  project       = "pya"
  project_short = "pya"
  environment   = var.environment
  service       = "web"
  service_short = "web"

  memory = var.web_memory
  cpu = var.web_cpu

  domain                   = var.domain
  subdomain                = "origin"
  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
  public_subnets           = module.vpc.public_subnets
  logging_key_id           = module.logging.kms_key_arn
  ingress_prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  container_port           = 3000
  create_endpoint          = true
  create_repository        = true
  create_version_parameter = true
  public                   = false
  health_check_path        = "/up"
  enable_execute_command   = true
  force_new_deployment     = true
  manage_performance_log_group = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn, aws_iam_policy.rds_db_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn, aws_iam_policy.rds_db_access.arn]

  environment_variables = {
    RACK_ENV      = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET     = module.submission_pdfs.bucket
    REVIEW_APP    = var.review_app
    DATABASE_USER = local.database_user
  }
  environment_secrets = {
    SECRET_KEY_BASE             = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
    SENTRY_DSN                  = "${module.secrets.secrets["sentry_dsn"].secret_arn}:key"
    SSN_HASHING_KEY             = "${module.secrets.secrets["ssn_hashing_key"].secret_arn}:key"
    TWILIO_ACCOUNT_SID          = "${module.secrets.secrets["twilio_account_sid"].secret_arn}:key"
    TWILIO_AUTH_TOKEN           = "${module.secrets.secrets["twilio_auth_token"].secret_arn}:key"
    TWILIO_MESSAGING_SERVICE    = "${module.secrets.secrets["twilio_messaging_service_sid"].secret_arn}:key"
    MAILGUN_API_KEY             = "${module.secrets.secrets["mailgun_api_key"].secret_arn}:key"
    MAILGUN_DOMAIN              = "${module.secrets.secrets["mailgun_domain"].secret_arn}:key"
    MAILGUN_BASIC_AUTH_NAME     = "${module.secrets.secrets["mailgun_basic_auth_name"].secret_arn}:key"
    MAILGUN_BASIC_AUTH_PASSWORD = "${module.secrets.secrets["mailgun_basic_auth_password"].secret_arn}:key"
    INTERCOM_APP_ID             = "${module.secrets.secrets["intercom_app_id"].secret_arn}:key"
    INTERCOM_SECURE_MODE_SECRET_KEY = "${module.secrets.secrets["intercom_secure_mode_secret_key"].secret_arn}:key"
  }
}

module "workers" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.9.0"

  project       = "pya"
  project_short = "pya"
  environment   = var.environment
  service       = "worker"
  service_short = "wrk"

  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  public_subnets         = module.vpc.public_subnets
  logging_key_id         = module.logging.kms_key_arn
  container_port         = 3000
  version_parameter      = module.web.version_parameter
  image_url              = module.web.repository_url
  create_endpoint        = false
  create_repository      = false
  enable_execute_command = true
  force_new_deployment   = true
  manage_performance_log_group = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn, aws_iam_policy.rds_db_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn, aws_iam_policy.rds_db_access.arn]

  environment_variables = {
    RACK_ENV      = var.environment
    DATABASE_HOST = module.database.cluster_endpoint
    S3_BUCKET     = module.submission_pdfs.bucket
    REVIEW_APP    = var.review_app
    DATABASE_USER = local.database_user
  }
  environment_secrets = {
    SECRET_KEY_BASE             = "${module.secrets.secrets["rails_secret_key_base"].secret_arn}:key"
    SENTRY_DSN                  = "${module.secrets.secrets["sentry_dsn"].secret_arn}:key"
    SSN_HASHING_KEY             = "${module.secrets.secrets["ssn_hashing_key"].secret_arn}:key"
    TWILIO_ACCOUNT_SID          = "${module.secrets.secrets["twilio_account_sid"].secret_arn}:key"
    TWILIO_AUTH_TOKEN           = "${module.secrets.secrets["twilio_auth_token"].secret_arn}:key"
    TWILIO_MESSAGING_SERVICE    = "${module.secrets.secrets["twilio_messaging_service_sid"].secret_arn}:key"
    MAILGUN_API_KEY             = "${module.secrets.secrets["mailgun_api_key"].secret_arn}:key"
    MAILGUN_DOMAIN              = "${module.secrets.secrets["mailgun_domain"].secret_arn}:key"
    MAILGUN_BASIC_AUTH_NAME     = "${module.secrets.secrets["mailgun_basic_auth_name"].secret_arn}:key"
    MAILGUN_BASIC_AUTH_PASSWORD = "${module.secrets.secrets["mailgun_basic_auth_password"].secret_arn}:key"
  }

  container_command = ["bundle", "exec", "rake", "jobs:work"]
  repository_arn    = module.web.repository_arn
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.5.1"

  project             = "pya"
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
  password_rotation_frequency = 30

  min_capacity       = 0
  max_capacity       = 10
  cluster_parameters = []

  tags = {
    "aws-backup/rds" = "daily"
    Project          = "pya"
    Environment      = var.environment
  }
}

module "backup_vault" {
  source  = "cloudposse/backup/aws"
  version = "1.1.1"

  providers = {
    aws = aws.backup
  }

  namespace  = "cfa"
  stage      = var.environment
  name       = "pya"
  attributes = ["database_backup_vault"]

  labels_as_tags = []
  tags = {
    Attributes  = "rds-dr"
    Namespace   = "cfa"
  }

  vault_enabled    = true
  iam_role_enabled = true
  plan_enabled     = false
}

module "backup" {
  source  = "cloudposse/backup/aws"
  version = "1.1.1"

  namespace  = "cfa"
  stage      = var.environment
  name       = "pya"
  attributes = ["database_back"]
  labels_as_tags = []

  plan_name_suffix = "aws-backup-daily"
  vault_enabled    = true
  iam_role_enabled = true
  plan_enabled     = true

  selection_tags = [
    {
      type  = "STRINGEQUALS"
      key   = "aws-backup/rds"
      value = "daily"
    }
  ]

  rules = [
    {
      name              = "pya-${var.environment}-daily"
      schedule          = "cron(0 18 ? * * *)"
      start_window      = 320
      completion_window = 1440

      lifecycle = {
        delete_after = 31
      }

      copy_action = {
        destination_vault_arn = module.backup_vault.backup_vault_arn
        lifecycle = {
          delete_after = 31
        }
      }
    },
    {
      name              = "pya-${var.environment}-monthly"
      schedule          = "cron(0 18 1 * ? *)"
      start_window      = 320
      completion_window = 1440

      lifecycle = {
        delete_after = 395
      }

      copy_action = {
        destination_vault_arn = module.backup_vault.backup_vault_arn
        lifecycle = {
          delete_after = 395
        }
      }
    },
    {
      name              = "pya-${var.environment}-yearly"
      schedule          = "cron(0 18 1 1 ? *)"
      start_window      = 320
      completion_window = 1440

      lifecycle = {
        delete_after = 1095
      }

      copy_action = {
        destination_vault_arn = module.backup_vault.backup_vault_arn
        lifecycle = {
          delete_after = 1095
        }
      }
    }
  ]

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
    bucket_arn : module.submission_pdfs.bucket,
    environment : var.environment
  })
}

resource "aws_kms_key" "docs" {
  description             = "OpenTofu docs S3 encryption key for pya ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("${path.module}/templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : module.docs.bucket,
    environment : var.environment
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
          module.submission_pdfs.arn,
          "${module.submission_pdfs.arn}/*",
          aws_kms_key.submission_pdfs.arn,
          module.docs.arn,
          "${module.docs.arn}/*",
          aws_kms_key.docs.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "rds_db_access" {
  name = "pya-${var.environment}-rds-db-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.identity.account_id}:dbuser:${module.database.cluster_resource_id}/pya-${var.environment}-rds"
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

resource "aws_cloudwatch_log_subscription_filter" "datadog" {
  for_each = length(local.datadog_lambda) > 0 ? toset(["web", "worker"]) : toset([])

  name            = "datadog"
  log_group_name  = "/aws/ecs/pya/${var.environment}/${each.key}"
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.datadog["this"].arn
}

resource "aws_wafv2_ip_set" "scanners" {
  for_each = var.allow_security_scans ? toset(["this"]) : []

  name               = "${var.project}-${var.environment}-security-scanners"
  description        = "Security scanners that are allowed to access the site."
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.security_scan_cidrs
}

module "cloudfront_waf" {
  source = "github.com/codeforamerica/tofu-modules-aws-cloudfront-waf?ref=1.12.0"

  project        = "pya"
  environment    = var.environment
  domain         = var.domain
  subdomain      = ""
  origin_alb_arn = module.web.load_balancer_arn
  log_bucket     = module.logging.bucket_domain_name
  log_group      = module.logging.log_groups["waf"]
  passive        = var.passive_waf

  ip_set_rules = var.allow_security_scans ? {
    tenable_one = {
      name     = "${var.project}-${var.environment}-security-scanners"
      priority = 0
      action   = "allow"
      arn      = aws_wafv2_ip_set.scanners["this"].arn
    }
  } : {}

  rate_limit_rules = var.rate_limit_requests > 0 ? {
    base = {
      action   = var.passive_waf ? "count" : "block"
      priority = 100
      limit    = var.rate_limit_requests
      window   = var.rate_limit_window
    }
  } : {}
}
