resource "aws_s3_bucket" "submission_pdfs" {
  bucket        = "submission-pdfs"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "submission_pdfs" {
  bucket = aws_s3_bucket.submission_pdfs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "submission_pdfs" {
  bucket = aws_s3_bucket.submission_pdfs.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.submission_pdfs.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "submission_pdfs" {
  bucket = aws_s3_bucket.submission_pdfs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "submission_pdfs" {
  bucket        = aws_s3_bucket.submission_pdfs.id
  target_bucket = aws_s3_bucket.submission_pdfs.id
  target_prefix = "${local.aws_logs_path}/s3accesslogs/${aws_s3_bucket.submission_pdfs.id}"
}

resource "aws_s3_bucket_policy" "submission_pdfs" {
  bucket = aws_s3_bucket.submission_pdfs.id
  policy = templatefile("${path.module}/templates/bucket-policy.json.tftpl", {
    account : data.aws_caller_identity.identity.account_id
    partition : data.aws_partition.current.partition
    bucket : aws_s3_bucket.submission_pdfs.bucket
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "submission_pdfs" {
  bucket = aws_s3_bucket.submission_pdfs.id

  rule {
    id     = "state"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.state_version_expiration
    }
  }
}

