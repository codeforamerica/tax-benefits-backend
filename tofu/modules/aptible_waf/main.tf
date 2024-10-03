resource "aws_wafv2_ip_set" "scanners" {
  for_each = var.allow_security_scanners ? toset(["this"]) : []

  name               = "${var.project}-${var.environment}-security-scanners"
  description        = "Security scanners that are allowed to access the site."
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = [
    # Detectify
    "52.17.9.21/32",
    "52.17.98.131/32",
    # SecurityMetrics
    "162.211.152.0/24"
  ]
}

module "waf" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aws/cloudfront_waf"

  project     = var.project
  environment = var.environment
  domain      = var.domain
  log_bucket  = var.log_bucket
  log_group   = var.log_group

  ip_set_rules = var.allow_security_scanners ? {
    detectify = {
      name     = "fyst-demo-security-scanners"
      priority = 0
      action   = "allow"
      arn      = aws_wafv2_ip_set.scanners["this"].arn
    }
  } : {}
}

# TODO: Aptible endpoints only support up to 50 CIDRs, while CloudFront has 99.
# data "aws_ip_ranges" "cloudfront" {
#   regions  = ["global"]
#   services = ["cloudfront"]
# }

module "endpoint" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules/aptible/managed_endpoint"

  aptible_environment = var.aptible_environment
  aptible_resource    = 17865
  domain              = var.domain
  subdomain           = "origin.demo"
  public              = true

  # TODO: Aptible endpoints only support up to 50 CIDRs, while CloudFront has 99.
  # allowed_cidrs = data.aws_ip_ranges.cloudfront.cidr_blocks
}
