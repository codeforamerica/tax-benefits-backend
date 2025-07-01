# Lambda function configurations with VPC support

# Text Extract Lambda
resource "aws_lambda_function" "text_extract" {
  function_name = "${local.name_prefix}-text-extract"

  filename         = local.lambda_filename
  source_code_hash = local.lambda_source_code_hash

  handler = "src.external.aws.lambdas.text_extractor.lambda_handler"

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = ["arm64"]

  kms_key_arn = local.kms_key_id

  role = aws_iam_role.execution_role.arn

  environment {
    variables = local.textract_environment_variables
  }

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [local.lambda_security_group_id]
    }
  }

  # Dead letter queue
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_text_extract,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-text-extract"
  })
}

resource "aws_lambda_permission" "allow_bucket_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.text_extract.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.document_storage.arn
}

resource "aws_lambda_provisioned_concurrency_config" "text_extract" {
  count = var.environment == "production" ? 1 : 0

  function_name                     = aws_lambda_function.text_extract.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.text_extract.version
}

# SQS to DynamoDB Writer Lambda
resource "aws_lambda_function" "sqs_dynamo_writer" {
  function_name = "${local.name_prefix}-sqs-dynamo-writer"

  filename         = local.lambda_filename
  source_code_hash = local.lambda_source_code_hash

  handler = "src.external.aws.lambdas.sqs_dynamo_writer.lambda_handler"

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = ["arm64"]

  kms_key_arn = local.kms_key_id

  role = aws_iam_role.execution_role.arn

  environment {
    variables = {
      SQS_QUEUE_URL  = aws_sqs_queue.queue_to_dynamo.url
      DYNAMODB_TABLE = aws_dynamodb_table.extracted_data.name
    }
  }

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [local.lambda_security_group_id]
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_sqs_dynamo_writer,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-dynamo-writer"
  })
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn                   = aws_sqs_queue.queue_to_dynamo.arn
  function_name                      = aws_lambda_function.sqs_dynamo_writer.arn
  maximum_batching_window_in_seconds = 0

  depends_on = [aws_iam_role_policy_attachment.sqs]
}

resource "aws_lambda_provisioned_concurrency_config" "sqs_dynamo_writer" {
  count = var.environment == "production" ? 1 : 0

  function_name                     = aws_lambda_function.sqs_dynamo_writer.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.sqs_dynamo_writer.version
}

# Authenticate Lambda
resource "aws_lambda_function" "authenticate" {
  function_name = "${local.name_prefix}-authenticate"

  filename         = local.lambda_filename
  source_code_hash = local.lambda_source_code_hash

  handler = "src.external.aws.lambdas.authenticate.lambda_handler"

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = ["arm64"]

  kms_key_arn = local.kms_key_id

  role = aws_iam_role.execution_role.arn

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [local.lambda_security_group_id]
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_authenticate,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-authenticate"
  })
}

resource "aws_lambda_permission" "api_gateway_invoke_authenticate" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authenticate.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_provisioned_concurrency_config" "authenticate" {
  count = var.environment == "production" ? 1 : 0

  function_name                     = aws_lambda_function.authenticate.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.authenticate.version
}

# S3 File Upload Lambda
resource "aws_lambda_function" "s3_file_upload" {
  function_name = "${local.name_prefix}-s3-file-upload"

  filename         = local.lambda_filename
  source_code_hash = local.lambda_source_code_hash

  handler = "src.external.aws.lambdas.s3_file_upload.lambda_handler"

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = ["arm64"]

  kms_key_arn = local.kms_key_id

  role = aws_iam_role.execution_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.document_storage.id
    }
  }

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [local.lambda_security_group_id]
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_s3_file_upload,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-file-upload"
  })
}

resource "aws_lambda_permission" "api_gateway_invoke_s3_upload" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_file_upload.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Get Extracted Document Lambda
resource "aws_lambda_function" "get_extracted_document" {
  function_name = "${local.name_prefix}-get-extracted-document"

  filename         = local.lambda_filename
  source_code_hash = local.lambda_source_code_hash

  handler = "src.external.aws.lambdas.get_extracted_document.lambda_handler"

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = ["arm64"]

  kms_key_arn = local.kms_key_id

  role = aws_iam_role.execution_role.arn

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.extracted_data.name
    }
  }

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [local.lambda_security_group_id]
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_get_extracted_document,
    aws_iam_role_policy_attachment.cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-get-extracted-document"
  })
}

resource "aws_lambda_permission" "api_gateway_invoke_get_document" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_extracted_document.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}