resource "aws_athena_workgroup" "this" {
  name = var.workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_database" "this" {
  name   = var.database_name
  bucket = aws_s3_bucket.athena_results.id
}

resource "aws_s3_bucket" "athena_results" {
  bucket = var.result_bucket_name
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "expire-results"
    status = "Enabled"

    expiration {
      days = var.result_retention_days
    }
  }
}

resource "aws_iam_policy" "athena_access" {
  name        = "${var.workgroup_name}-athena-access"
  description = "Provides access for Athena to query specific buckets and manage results."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:CreateMultipartUpload",
          "s3:PutObject"
        ]
        Resource = flatten([
          [
            aws_s3_bucket.athena_results.arn,
            "${aws_s3_bucket.athena_results.arn}/*"
          ],
          [for arn in var.source_bucket_arns : arn],
          [for arn in var.source_bucket_arns : "${arn}/*"]
        ])
      },
      {
        Effect = "Allow"
        Action = [
          "athena:GetDataCatalog",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = [aws_athena_workgroup.this.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:UpdateTable",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
          "glue:GetPartition",
        ]
        Resource = "*"
      }
    ]
  })
}
