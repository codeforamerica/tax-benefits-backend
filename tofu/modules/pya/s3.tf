module "submission_pdfs" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = "${var.project}-${var.environment}-submission-pdfs"

  force_destroy = false

  bucket_policy = templatefile("${path.module}/templates/bucket-policy.json.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    bucket : module.submission_pdfs.id
  })

  lifecycle_configuration = [
    {
      id     = "state"
      status = "Enabled"

      filter = {
        prefix = ""
      }

      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_expiration = [{
        noncurrent_days = var.state_version_expiration
      }]

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.submission_pdfs.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = module.logging.bucket
    target_prefix = "${local.aws_logs_path}/s3accesslogs/${module.submission_pdfs.id}"
  }
}

module "docs" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = "${var.project}-${var.environment}-docs"

  force_destroy = false

  bucket_policy = templatefile("${path.module}/templates/bucket-policy.json.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    bucket : module.docs.id
  })

  lifecycle_configuration = [
    {
      id     = "state"
      status = "Enabled"

      filter = {
        prefix = ""
      }

      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_expiration = [{
        noncurrent_days = var.state_version_expiration
      }]

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.docs.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = module.logging.bucket
    target_prefix = "${local.aws_logs_path}/s3accesslogs/${module.submission_pdfs.id}"
  }
}
