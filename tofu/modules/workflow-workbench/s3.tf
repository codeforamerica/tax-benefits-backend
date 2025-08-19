# Document Storage Bucket (with full compliance)
resource "aws_s3_bucket" "document_storage" {
  bucket = "${local.name_prefix}-documents-${data.aws_caller_identity.current.account_id}"

  force_destroy = var.ephemeral_suffix != "" ? true : false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documents"
  })
}

resource "aws_s3_bucket_versioning" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/documents/"
}

resource "aws_s3_bucket_lifecycle_configuration" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  rule {
    id     = "delete-uploaded-documents"
    status = "Enabled"

    filter {
      prefix = "input/"
    }

    expiration {
      days = 31
    }
  }

  rule {
    id     = "transition-processed-documents"
    status = "Enabled"

    filter {
      prefix = "output/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_policy" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.document_storage.arn,
          "${aws_s3_bucket.document_storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "notify_on_input_data" {
  bucket = aws_s3_bucket.document_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.text_extract.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [aws_lambda_permission.allow_bucket_invoke]
}

# Website Storage Bucket (with CloudFront OAI)
resource "aws_s3_bucket" "website" {
  bucket = "${local.name_prefix}-website-${data.aws_caller_identity.current.account_id}"

  force_destroy = var.ephemeral_suffix != "" ? true : false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-website"
  })
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "website" {
  bucket = aws_s3_bucket.website.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/website/"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "${local.name_prefix} website OAI"
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website.iam_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload website files
module "read_website_files" {
  source  = "hashicorp/dir/template"
  version = "~> 1.0.2"

  base_dir = var.ui_dist_path
}

resource "aws_s3_object" "website_files" {
  for_each = module.read_website_files.files

  bucket = aws_s3_bucket.website.bucket
  key    = each.key
  source = each.value.source_path

  etag         = each.value.digests.md5
  content_type = each.value.content_type

  tags = local.common_tags
}