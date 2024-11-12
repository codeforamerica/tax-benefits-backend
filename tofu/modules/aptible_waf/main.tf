resource "aws_wafv2_ip_set" "scanners" {
  for_each = var.allow_security_scans ? toset(["this"]) : []

  name               = "${var.project}-${var.environment}-security-scanners"
  description        = "Security scanners that are allowed to access the site."
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = var.security_scan_cidrs
}

module "waf" {
  source = "github.com/codeforamerica/tofu-modules-aws-cloudfront-waf?ref=1.2.0"

  project     = var.project
  environment = var.environment
  domain      = var.domain
  log_bucket  = var.log_bucket
  log_group   = var.log_group
  passive     = var.passive
  subdomain   = local.subdomain

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

# TODO: Aptible endpoints only support up to 50 CIDRs, while CloudFront has 99.
# data "aws_ip_ranges" "cloudfront" {
#   regions  = ["global"]
#   services = ["cloudfront"]
# }

module "endpoint" {
  source = "github.com/codeforamerica/tofu-modules-aptible-managed-endpoint?ref=1.0.0"

  aptible_environment = var.aptible_environment
  aptible_resource    = var.aptible_app_id
  domain              = var.domain
  subdomain           = "origin.${local.subdomain}"
  public              = true

  # TODO: Aptible endpoints only support up to 50 CIDRs, while CloudFront has 99.
  # allowed_cidrs = data.aws_ip_ranges.cloudfront.cidr_blocks
}
