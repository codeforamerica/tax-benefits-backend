# API Gateway Endpoints Configuration

module "document_endpoints" {
  source = "./endpoint"

  api_gateway_name = aws_api_gateway_rest_api.api.name

  handler_method_mapping = [
    {
      name              = "create-document"
      handler_file_path = local.lambda_filename
      handler_package   = "src.external.aws.lambdas.s3_file_upload.lambda_handler"
      http_method       = "POST"
    },
  ]

  resource_prefix       = local.name_prefix
  path_part             = "document"
  resource_parent_id    = aws_api_gateway_rest_api.api.root_resource_id
  lambda_execution_role = aws_iam_role.execution_role.arn
  kms_key_arn           = local.kms_key_id

  environment_variables = {
    S3_BUCKET_NAME = aws_s3_bucket.document_storage.bucket
    DYNAMODB_TABLE = aws_dynamodb_table.extracted_data.name
  }

  authorizer = aws_api_gateway_authorizer.authorizer.id

  # VPC Configuration for Lambda
  vpc_config = local.vpc_config_enabled ? {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [local.lambda_security_group_id]
  } : null

  tags = local.common_tags

  depends_on = [aws_api_gateway_rest_api.api]
}

module "document_id_endpoints" {
  source = "./endpoint"

  api_gateway_name = aws_api_gateway_rest_api.api.name

  handler_method_mapping = [
    {
      name              = "get-document"
      handler_file_path = local.lambda_filename
      handler_package   = "src.external.aws.lambdas.get_extracted_document.lambda_handler"
      http_method       = "GET"
    },
    {
      name              = "update-document"
      handler_file_path = local.lambda_filename
      handler_package   = "src.external.aws.lambdas.update_extracted_document.lambda_handler"
      http_method       = "PUT"
    },
  ]

  resource_prefix       = local.name_prefix
  path_part             = "{document_id}"
  resource_parent_id    = module.document_endpoints.resource_id
  lambda_execution_role = aws_iam_role.execution_role.arn
  kms_key_arn           = local.kms_key_id

  environment_variables = {
    DYNAMODB_TABLE = aws_dynamodb_table.extracted_data.name
    S3_BUCKET      = aws_s3_bucket.document_storage.bucket
  }

  authorizer = aws_api_gateway_authorizer.authorizer.id

  # VPC Configuration for Lambda
  vpc_config = local.vpc_config_enabled ? {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [local.lambda_security_group_id]
  } : null

  tags = local.common_tags

  depends_on = [aws_api_gateway_rest_api.api]
}

module "token_endpoints" {
  source = "./endpoint"

  api_gateway_name = aws_api_gateway_rest_api.api.name

  handler_method_mapping = [
    {
      name              = "token"
      handler_file_path = local.lambda_filename
      handler_package   = "src.external.aws.lambdas.token.lambda_handler"
      http_method       = "POST"
    },
  ]

  resource_prefix       = local.name_prefix
  path_part             = "token"
  resource_parent_id    = aws_api_gateway_rest_api.api.root_resource_id
  lambda_execution_role = aws_iam_role.execution_role.arn
  kms_key_arn           = local.kms_key_id

  environment_variables = {
    ENVIRONMENT = var.environment
  }

  # No authorizer for token endpoint (it's the authentication endpoint)
  authorizer = null

  # VPC Configuration for Lambda
  vpc_config = local.vpc_config_enabled ? {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [local.lambda_security_group_id]
  } : null

  tags = local.common_tags

  depends_on = [aws_api_gateway_rest_api.api]
}