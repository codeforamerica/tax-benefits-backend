locals {
  subdomain = var.subdomain != "" ? var.subdomain : var.environment
  gyr_upload_paths = [{
    constraint = "ENDS_WITH"
    path       = "/documents"
  }]
}
