plugin "aws" {
  enabled = true
  version = "0.37.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  preset = "all"
  enabled = true
}

# TFLint doesn't understand the provider for_each syntax introduced with
# OpenTofu 1.9, so we need to disable these rules so it doesn't error out.
rule "terraform_required_providers" {
  enabled = false
}
rule "terraform_unused_required_providers" {
  enabled = false
}
