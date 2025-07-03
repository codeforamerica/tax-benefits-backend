# API Gateway with compliance features
resource "aws_api_gateway_rest_api" "api" {
  name        = "${local.name_prefix}-api"
  description = "${var.project} API for ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api"
  })
}

# API Gateway Account (for CloudWatch logging)
resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# IAM role for API Gateway CloudWatch logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gateway-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-gateway-cloudwatch"
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment_for_document    = module.document_endpoints.resource_method_integration_configuration_hash
    redeployment_for_document_id = module.document_id_endpoints.resource_method_integration_configuration_hash
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.document_endpoints,
    module.document_id_endpoints
  ]
}

# API Gateway Stage with logging
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
  deployment_id = aws_api_gateway_deployment.deployment.id

  # Enable CloudWatch logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  # Enable X-Ray tracing
  xray_tracing_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-v1"
  })
}

# Method settings for all methods
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled      = true
    logging_level        = "INFO"
    data_trace_enabled   = var.environment != "production" # Disable in prod for security
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "authorizer" {
  name                             = "${local.name_prefix}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  authorizer_uri                   = aws_lambda_function.authenticate.invoke_arn
  authorizer_result_ttl_in_seconds = 300
  type                             = "REQUEST"

  identity_source = "method.request.header.Authorization"
}

# API Gateway Usage Plan (for rate limiting)
resource "aws_api_gateway_usage_plan" "plan" {
  name        = "${local.name_prefix}-usage-plan"
  description = "Usage plan for ${var.project} API"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 100000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 10000
    burst_limit = 5000
  }
}

# WAF Web ACL for API Gateway (optional)
resource "aws_wafv2_web_acl_association" "api_gateway" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api[0].arn
}