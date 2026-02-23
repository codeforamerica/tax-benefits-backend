locals {
  tags = {
    module = "athena"
  }
}

resource "aws_athena_workgroup" "this" {
  name = var.workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_results.bucket}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena.arn
      }
    }
  }
}

resource "aws_athena_database" "this" {
  name   = var.database_name
  bucket = module.athena_results.id

  encryption_configuration {
    encryption_option = "SSE_KMS"
    kms_key           = aws_kms_key.athena.arn
  }
}

resource "aws_kms_key" "athena" {
  description             = "KMS key for Athena workgroup ${var.workgroup_name} and results bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/key-policy.yaml.tftpl", {
    account   = data.aws_caller_identity.current.account_id
    bucket    = var.result_bucket_name
    partition = data.aws_partition.current.partition
  })))

  tags = local.tags
}

resource "aws_kms_alias" "athena" {
  name          = "alias/athena/${var.workgroup_name}"
  target_key_id = aws_kms_key.athena.arn
}

module "athena_results" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = var.result_bucket_name

  bucket_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/bucket-policy.yaml.tftpl", {
    partition = data.aws_partition.current.partition
    bucket    = var.result_bucket_name
  })))

  lifecycle_configuration = [{
    id     = "expire-results"
    status = "Enabled"

    filter = {
      prefix = ""
    }

    abort_incomplete_multipart_upload_days = 7

    expiration = {
      days = var.result_retention_days
    }
  }]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.athena.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = var.log_bucket
    target_prefix = "s3accesslogs/${var.result_bucket_name}/"
  }

  tags = local.tags
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

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
            module.athena_results.arn,
            "${module.athena_results.arn}/*"
          ],
          [for arn in var.source_bucket_arns : arn],
          [for arn in var.source_bucket_arns : "${arn}/*"]
        ])
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [aws_kms_key.athena.arn]
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
