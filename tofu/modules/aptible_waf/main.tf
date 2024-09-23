module "waf" {
  # TODO: Create releases for tofu-modules and pin to a release.
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules?ref=aptible-endpoint/aws/cloudfront_waf"

  project     = var.project
  environment = var.environment
  domain      = var.domain
  log_bucket  = var.log_bucket
  log_group   = var.log_group
}

data "aws_ip_ranges" "cloudfront" {
  regions  = ["global"]
  services = ["cloudfront"]
}

module "endpoint" {
  # tflint-ignore: terraform_module_pinned_source
  source = "github.com/codeforamerica/tofu-modules?ref=aptible-endpoint/aptible/managed_endpoint"

  aptible_environment = var.aptible_environment
  aptible_resource = "17865"
  domain = var.domain
  subdomain = "origin.demo"
  public = true

  # TODO: This fails with "Ip whitelist must contain at most 50 addresses or CIDRs"
#   allowed_cidrs = data.aws_ip_ranges.cloudfront.cidr_blocks
}
