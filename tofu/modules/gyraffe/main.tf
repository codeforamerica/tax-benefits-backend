module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.2"

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
  source = "github.com/codeforamerica/tofu-modules-aws-secrets?ref=2.1.1"

  project     = "gyraffe"
  environment = var.environment
  add_suffix  = false

  secrets = {
    "SECRET_KEY_BASE" = {
      description = "secret_key_base for Rails app"
    },
    "TWILIO_ACCOUNT_SID" = {
      description = "account sid for twilio"
    },
    "TWILIO_AUTH_TOKEN" = {
      description = "auth token for twilio"
    },
    "TWILIO_MESSAGING_SERVICE_SID" = {
      description = "messaging service sid for twilio"
    },
    "MAILGUN_API_KEY" = {
      description = "API key for Mailgun"
    },
    "MAILGUN_DOMAIN" = {
      description = "Domain used with Mailgun"
    },
    "MAILGUN_BASIC_AUTH_NAME" = {
      description = "Basic auth username for Mailgun"
    },
    "MAILGUN_BASIC_AUTH_PASSWORD" = {
      description = "Basic auth password for Mailgun"
    },
    "SENTRY_DSN" = {
      description = "Data Source Name (DSN) for sentry integration"
    },
    "BASE_URL" = {
      description = "Base application URL"
    },
    "EFILER_API_URL" = {
      description = "Base efiler API URL"
    },
    "EFILER_API_CLIENT_NAME" = {
      description = "Name to use when making requests to efiler API"
    },
    "EFILER_API_CLIENT_PRIVATE_KEY_BASE64" = {
      description = "Private key for signing requests to efiler API"
    },
    "IRS_EFIN" = {
      description = "Electronic Filing Identification Number for CFA"
    },
    "IRS_ETIN" = {
      description = "Electronic Transmitter Identification Number for CFA testing/prod environment"
    },
    "IRS_SOFTWARE_ID" = {
      description = "Software ID for this product"
    },
    "MIXPANEL_TOKEN" = {
      description = "Mixpanel token"
    },
    "INTERCOM_APP_ID" = {
      description = "Intercom app ID"
    },
    "INTERCOM_SECURE_MODE_SECRET_KEY" = {
      description = "Intercom secure mode secret key"
    },
    "EFILER_API_CALLBACK_SECRET" = {
      description = "Shared secret for authenticating EFiler API callbacks"
    }
  }
}

module "doppler" {
  source     = "github.com/codeforamerica/tofu-modules-aws-doppler?ref=1.1.0"
  depends_on = [module.secrets]

  project              = "gyraffe"
  doppler_project      = "tax-gyraffe"
  environment          = var.environment
  kms_key_arns         = [module.secrets.kms_key_arn]
  doppler_workspace_id = "08430c37e2a2889dc220"
}

module "vpc" {
  source = "github.com/codeforamerica/tofu-modules-aws-vpc?ref=1.1.2"

  project        = "gyraffe"
  environment    = var.environment
  cidr           = var.cidr
  logging_key_id = module.logging.kms_key_arn

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  peers           = var.vpc_peers
}

module "web" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.13.0"

  project       = "gyraffe"
  project_short = "gyraffe"
  environment   = var.environment
  service       = "web"
  service_short = "web"

  cpu = 2048
  memory = 4096

  # Wait for the deployment to be in a steady state, and rollback if it fails.
  enable_circuit_breaker          = true
  enable_circuit_breaker_rollback = true
  wait_for_steady_state           = true

  domain                   = var.domain
  subdomain                = "origin"
  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
  public_subnets           = module.vpc.public_subnets
  logging_key_id           = module.logging.kms_key_arn
  ingress_prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  container_port           = 8080
  create_endpoint          = true
  create_repository        = true
  create_version_parameter = true
  public                   = false
  health_check_path        = "/up"
  enable_execute_command   = true
  force_new_deployment     = true
  use_target_group_port_suffix = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RAILS_ENV         = var.environment
    DATABASE_HOST     = module.database.cluster_endpoint
    REVIEW_APP        = var.review_app
    SCHEMA_S3_BUCKET  = module.schemas.bucket
    SUBMISSION_BUNDLES_S3_BUCKET = module.submission_bundles.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD           = "${module.database.secret_arn}:password"
    DATABASE_USER               = "${module.database.secret_arn}:username"
    BASE_URL                    = module.secrets.secrets["BASE_URL"].secret_arn
    SECRET_KEY_BASE             = module.secrets.secrets["SECRET_KEY_BASE"].secret_arn
    SENTRY_DSN                  = module.secrets.secrets["SENTRY_DSN"].secret_arn
    TWILIO_ACCOUNT_SID          = module.secrets.secrets["TWILIO_ACCOUNT_SID"].secret_arn
    TWILIO_AUTH_TOKEN           = module.secrets.secrets["TWILIO_AUTH_TOKEN"].secret_arn
    TWILIO_MESSAGING_SERVICE_SID = module.secrets.secrets["TWILIO_MESSAGING_SERVICE_SID"].secret_arn
    MAILGUN_API_KEY             = module.secrets.secrets["MAILGUN_API_KEY"].secret_arn
    MAILGUN_DOMAIN              = module.secrets.secrets["MAILGUN_DOMAIN"].secret_arn
    MAILGUN_BASIC_AUTH_NAME     = module.secrets.secrets["MAILGUN_BASIC_AUTH_NAME"].secret_arn
    MAILGUN_BASIC_AUTH_PASSWORD = module.secrets.secrets["MAILGUN_BASIC_AUTH_PASSWORD"].secret_arn
    EFILER_API_URL              = module.secrets.secrets["EFILER_API_URL"].secret_arn
    EFILER_API_CLIENT_NAME      = module.secrets.secrets["EFILER_API_CLIENT_NAME"].secret_arn
    EFILER_API_CLIENT_PRIVATE_KEY_BASE64 = module.secrets.secrets["EFILER_API_CLIENT_PRIVATE_KEY_BASE64"].secret_arn
    IRS_EFIN                    = module.secrets.secrets["IRS_EFIN"].secret_arn
    IRS_ETIN                    = module.secrets.secrets["IRS_ETIN"].secret_arn
    IRS_SOFTWARE_ID             = module.secrets.secrets["IRS_SOFTWARE_ID"].secret_arn
    MIXPANEL_TOKEN              = module.secrets.secrets["MIXPANEL_TOKEN"].secret_arn
    INTERCOM_APP_ID                 = module.secrets.secrets["INTERCOM_APP_ID"].secret_arn
    INTERCOM_SECURE_MODE_SECRET_KEY = module.secrets.secrets["INTERCOM_SECURE_MODE_SECRET_KEY"].secret_arn
    EFILER_API_CALLBACK_SECRET = module.secrets.secrets["EFILER_API_CALLBACK_SECRET"].secret_arn
  }
}

module "workers" {
  source = "github.com/codeforamerica/tofu-modules-aws-fargate-service?ref=1.13.0"

  project       = "gyraffe"
  project_short = "gyraffe"
  environment   = var.environment
  service       = "worker"
  service_short = "worker"

  cpu = 2048
  memory = 4096

  # Wait for the deployment to be in a steady state, and rollback if it fails.
  enable_circuit_breaker          = true
  enable_circuit_breaker_rollback = true
  wait_for_steady_state           = true

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
  force_new_deployment   = true

  execution_policies = [aws_iam_policy.ecs_s3_access.arn]
  task_policies      = [aws_iam_policy.ecs_s3_access.arn]

  environment_variables = {
    RAILS_ENV         = var.environment
    DATABASE_HOST     = module.database.cluster_endpoint
    REVIEW_APP        = var.review_app
    SCHEMA_S3_BUCKET  = module.schemas.bucket
    SUBMISSION_BUNDLES_S3_BUCKET = module.submission_bundles.bucket
  }
  environment_secrets = {
    DATABASE_PASSWORD           = "${module.database.secret_arn}:password"
    DATABASE_USER               = "${module.database.secret_arn}:username"
    BASE_URL                    = module.secrets.secrets["BASE_URL"].secret_arn
    SECRET_KEY_BASE             = module.secrets.secrets["SECRET_KEY_BASE"].secret_arn
    SENTRY_DSN                  = module.secrets.secrets["SENTRY_DSN"].secret_arn
    TWILIO_ACCOUNT_SID          = module.secrets.secrets["TWILIO_ACCOUNT_SID"].secret_arn
    TWILIO_AUTH_TOKEN           = module.secrets.secrets["TWILIO_AUTH_TOKEN"].secret_arn
    TWILIO_MESSAGING_SERVICE_SID = module.secrets.secrets["TWILIO_MESSAGING_SERVICE_SID"].secret_arn
    MAILGUN_API_KEY             = module.secrets.secrets["MAILGUN_API_KEY"].secret_arn
    MAILGUN_DOMAIN              = module.secrets.secrets["MAILGUN_DOMAIN"].secret_arn
    MAILGUN_BASIC_AUTH_NAME     = module.secrets.secrets["MAILGUN_BASIC_AUTH_NAME"].secret_arn
    MAILGUN_BASIC_AUTH_PASSWORD = module.secrets.secrets["MAILGUN_BASIC_AUTH_PASSWORD"].secret_arn
    EFILER_API_URL              = module.secrets.secrets["EFILER_API_URL"].secret_arn
    EFILER_API_CLIENT_NAME      = module.secrets.secrets["EFILER_API_CLIENT_NAME"].secret_arn
    EFILER_API_CLIENT_PRIVATE_KEY_BASE64 = module.secrets.secrets["EFILER_API_CLIENT_PRIVATE_KEY_BASE64"].secret_arn
    IRS_EFIN                    = module.secrets.secrets["IRS_EFIN"].secret_arn
    IRS_ETIN                    = module.secrets.secrets["IRS_ETIN"].secret_arn
    IRS_SOFTWARE_ID             = module.secrets.secrets["IRS_SOFTWARE_ID"].secret_arn
    MIXPANEL_TOKEN              = module.secrets.secrets["MIXPANEL_TOKEN"].secret_arn
    INTERCOM_APP_ID                 = module.secrets.secrets["INTERCOM_APP_ID"].secret_arn
    INTERCOM_SECURE_MODE_SECRET_KEY = module.secrets.secrets["INTERCOM_SECURE_MODE_SECRET_KEY"].secret_arn
    EFILER_API_CALLBACK_SECRET = module.secrets.secrets["EFILER_API_CALLBACK_SECRET"].secret_arn
  }

  container_command = ["bin/jobs"]
  repository_arn    = module.web.repository_arn
}

module "database" {
  source = "github.com/codeforamerica/tofu-modules-aws-serverless-database?ref=1.8.0"

  project             = "gyraffe"
  environment         = var.environment
  service             = "web"
  skip_final_snapshot = true

  logging_key_arn    = module.logging.kms_key_arn
  secrets_key_arn    = module.secrets.kms_key_arn
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
  ingress_cidrs      = concat(module.vpc.private_subnets_cidr_blocks, var.additional_database_ingress)
  iam_authentication = true
  enable_data_api    = true
  password_rotation_frequency = 90

  min_capacity       = 0
  max_capacity       = 10
  cluster_parameters = []

  db_users = var.data_science_database_user != null && length(var.data_science_databases) > 0 ? {
      (var.data_science_database_user) = {
        databases  = var.data_science_databases
        privileges = "readonly"
      }
    } : {}
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


resource "aws_wafv2_ip_set" "scanners" {
  for_each = var.allow_security_scans ? toset(["this"]) : []

  name               = "${var.project}-${var.environment}-security-scanners"
  description        = "Security scanners that are allowed to access the site."
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.security_scan_cidrs
}

module "cloudfront_waf" {
  source = "github.com/codeforamerica/tofu-modules-aws-cloudfront-waf?ref=2.1.0"
  depends_on = [module.web.load_balancer_arn]

  project        = "gyraffe"
  environment    = var.environment
  domain         = var.domain
  subdomain      = ""
  origin_alb_arn = module.web.load_balancer_arn
  log_bucket     = module.logging.bucket_domain_name
  log_group      = module.logging.log_groups["waf"]
  passive        = var.passive_waf
  certificate_imported = var.environment == "production"

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

  # EFiler API submit callbacks contain XML in a JSON `result` field, which
  # trips CrossSiteScripting_BODY in the AWS managed CommonRuleSet. Allow
  # requests to the callback paths through the WAF, but only when the
  # X-EFiler-Callback-Secret header set by EFiler API is present
  webhooks = {
    efiler_api_callback = {
      paths = [
        { constraint = "EXACTLY", path = "/efiler-api/submit-callback" },
        { constraint = "EXACTLY", path = "/efiler-api/submissions-status-callback" },
        { constraint = "EXACTLY", path = "/efiler-api/acks-callback" },
      ]
      criteria = [
        {
          type       = "size"
          constraint = "GT"
          field      = "header"
          name       = "x-efiler-callback-secret"
          value      = "0"
        }
      ]
      action = "allow"
    }
  }
}
