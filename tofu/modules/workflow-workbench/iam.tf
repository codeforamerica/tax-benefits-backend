# Lambda Execution Role
resource "aws_iam_role" "execution_role" {
  name = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-execution-role"
  })
}

# VPC Lambda Execution Policy
resource "aws_iam_role_policy_attachment" "vpc_execution" {
  count      = local.vpc_config_enabled ? 1 : 0
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Basic Lambda Execution Policy
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Logs Policy (with least privilege)
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda_authenticate.arn}:*",
      "${aws_cloudwatch_log_group.lambda_text_extract.arn}:*",
      "${aws_cloudwatch_log_group.lambda_s3_file_upload.arn}:*",
      "${aws_cloudwatch_log_group.lambda_get_extracted_document.arn}:*",
      "${aws_cloudwatch_log_group.lambda_sqs_dynamo_writer.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name   = "${local.name_prefix}-lambda-logs"
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# DynamoDB Policy (least privilege)
data "aws_iam_policy_document" "dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.extracted_data.arn,
      "${aws_dynamodb_table.extracted_data.arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "dynamodb" {
  name   = "${local.name_prefix}-dynamodb"
  policy = data.aws_iam_policy_document.dynamodb.json
}

resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.dynamodb.arn
}

# S3 Policy (least privilege)
data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.document_storage.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.document_storage.arn
    ]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "${local.name_prefix}-s3"
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.s3.arn
}

# KMS Policy
data "aws_iam_policy_document" "kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [local.kms_key_id]
  }
}

resource "aws_iam_policy" "kms" {
  name   = "${local.name_prefix}-kms"
  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_iam_role_policy_attachment" "kms" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.kms.arn
}

# SQS Policy (least privilege)
data "aws_iam_policy_document" "sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.queue_to_dynamo.arn,
      aws_sqs_queue.dlq.arn
    ]
  }
}

resource "aws_iam_policy" "sqs" {
  name   = "${local.name_prefix}-sqs"
  policy = data.aws_iam_policy_document.sqs.json
}

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.sqs.arn
}

# Secrets Manager Policy (scoped)
data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.name_prefix}-*"
    ]
  }
}

resource "aws_iam_policy" "secrets" {
  name   = "${local.name_prefix}-secrets"
  policy = data.aws_iam_policy_document.secrets.json
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.secrets.arn
}

# Textract Policy
data "aws_iam_policy_document" "textract" {
  statement {
    effect = "Allow"
    actions = [
      "textract:AnalyzeDocument",
      "textract:DetectDocumentText",
      "textract:GetDocumentAnalysis",
      "textract:GetDocumentTextDetection"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "textract" {
  name   = "${local.name_prefix}-textract"
  policy = data.aws_iam_policy_document.textract.json
}

resource "aws_iam_role_policy_attachment" "textract" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.textract.arn
}