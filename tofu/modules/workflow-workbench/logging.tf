# API Gateway Logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-gateway"
  })
}

# Lambda Function Logs
resource "aws_cloudwatch_log_group" "lambda_authenticate" {
  name              = "/aws/lambda/${local.name_prefix}-authenticate"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-authenticate"
  })
}

resource "aws_cloudwatch_log_group" "lambda_text_extract" {
  name              = "/aws/lambda/${local.name_prefix}-text-extract"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-text-extract"
  })
}

resource "aws_cloudwatch_log_group" "lambda_s3_file_upload" {
  name              = "/aws/lambda/${local.name_prefix}-s3-file-upload"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-s3-file-upload"
  })
}

resource "aws_cloudwatch_log_group" "lambda_get_extracted_document" {
  name              = "/aws/lambda/${local.name_prefix}-get-extracted-document"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-get-extracted-document"
  })
}

resource "aws_cloudwatch_log_group" "lambda_sqs_dynamo_writer" {
  name              = "/aws/lambda/${local.name_prefix}-sqs-dynamo-writer"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sqs-dynamo-writer"
  })
}

# S3 Access Logging Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs-${data.aws_caller_identity.current.account_id}"

  force_destroy = var.ephemeral_suffix != "" ? true : false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-logs"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # Note: Logging buckets must use AWS managed keys per compliance requirements
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
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