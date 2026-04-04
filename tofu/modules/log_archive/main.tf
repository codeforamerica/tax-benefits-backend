resource "aws_kms_key" "this" {
  description             = "Encryption key for log archive bucket ${var.bucket_name}"
  deletion_window_in_days = var.key_recovery_period
  enable_key_rotation     = true
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account : data.aws_caller_identity.current.account_id
    bucket : var.bucket_name
    datadog_role : var.datadog_role_name
    partition : data.aws_partition.current.partition
  })))

  tags = local.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.bucket_name}"
  target_key_id = aws_kms_key.this.arn
}

module "this" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = var.bucket_name

  bucket_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    partition : data.aws_partition.current.partition
    bucket : var.bucket_name
  })))

  lifecycle_configuration = [{
    id     = "state"
    status = "Enabled"

    filter = {
      prefix = ""
    }

    abort_incomplete_multipart_upload_days = 7

    noncurrent_version_expiration = [{
      noncurrent_days = 30
    }]

    expiration = {
      days = var.retention_period
    }
  }]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.this.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = var.logging_bucket
    target_prefix = "${local.logs_path}/s3accesslogs/${var.bucket_name}"
  }

  tags = local.tags
}

resource "aws_iam_policy" "datadog" {
  name        = "${var.bucket_name}-datadog-policy"
  description = "IAM policy for Datadog to access log archive bucket ${var.bucket_name}"
  policy      = jsonencode(yamldecode(templatefile("${path.module}/templates/iam-policy.yaml.tftpl", {
    partition : data.aws_partition.current.partition
    bucket : var.bucket_name
  })))
}

resource "aws_iam_role_policy_attachment" "datadog" {
  role       = var.datadog_role_name
  policy_arn = aws_iam_policy.datadog.arn
}
