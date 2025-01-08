resource "aws_wafv2_ip_set" "scanners" {
  for_each = var.allow_security_scans ? toset(["this"]) : []

  name               = "${var.project}-${var.environment}-security-scanners"
  description        = "Security scanners that are allowed to access the site."
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.security_scan_cidrs
}

module "origin_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.3"

  name_prefix            = "${var.project}/${var.environment}/origin/token-"
  create_random_password = true
  description            = "Token used to verify traffic at the origin."
  kms_key_id             = var.secrets_key_arn
  # TODO: Update the window
  recovery_window_in_days = 0

  ignore_secret_changes = true
}

data "aws_secretsmanager_secret_version" "origin_token" {
  secret_id = module.origin_secret.secret_id
}

module "waf" {
  source     = "github.com/codeforamerica/tofu-modules-aws-cloudfront-waf?ref=1.6.0"
  depends_on = [module.origin_secret.secret_id]

  project     = var.project
  environment = var.environment
  domain      = var.domain
  log_bucket  = var.log_bucket
  log_group   = var.log_group
  passive     = var.passive
  subdomain   = local.subdomain

  custom_headers = {
    x-origin-token = data.aws_secretsmanager_secret_version.origin_token.secret_string
  }

  upload_paths = var.allow_gyr_uploads ? local.gyr_upload_paths : []

  ip_set_rules = var.allow_security_scans ? {
    detectify = {
      name     = "fyst-demo-security-scanners"
      priority = 0
      action   = "allow"
      arn      = aws_wafv2_ip_set.scanners["this"].arn
    }
  } : {}

  rate_limit_rules = var.rate_limit_requests > 0 ? {
    base = {
      action   = var.passive ? "count" : "block"
      priority = 100
      limit    = var.rate_limit_requests
      window   = var.rate_limit_window
    }
  } : {}
}

module "endpoint" {
  source = "github.com/codeforamerica/tofu-modules-aptible-managed-endpoint?ref=1.0.0"

  aptible_environment = var.aptible_environment
  aptible_resource    = var.aptible_app_id
  domain              = var.domain
  subdomain           = "origin.${local.subdomain}"
  public              = true
}
