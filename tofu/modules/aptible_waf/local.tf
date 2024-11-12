locals {
  subdomain = var.subdomain != "" ? var.subdomain : var.environment
}
