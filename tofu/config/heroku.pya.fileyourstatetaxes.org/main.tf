# terraform {
#   backend "s3" {
#     bucket         = "pya-heroku-tfstate"
#     key            = "heroku.pya.fileyourstatetaxes.org"
#     region         = "us-east-1"
#     dynamodb_table = "heroku.tfstate"
#   }
# }
#
module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  project     = "pya"
  environment = "heroku"
}

module "logging" {
  source = "github.com/codeforamerica/tofu-modules-aws-logging?ref=2.1.0"

  project                  = "pya"
  environment              = "heroku"
  cloudwatch_log_retention = 30
}

locals {
  aws_logs_path = "/AWSLogs/${data.aws_caller_identity.identity.account_id}"
}

data "aws_caller_identity" "identity" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "heroku_submission_pdfs" {
  description             = "OpenTofu submission_pdfs S3 encryption key for pya heroku"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = templatefile("templates/key-policy.json.tftpl", {
    account_id : data.aws_caller_identity.identity.account_id,
    partition : data.aws_partition.current.partition,
    bucket_arn : aws_s3_bucket.heroku_submission_pdfs.bucket
  })
}
