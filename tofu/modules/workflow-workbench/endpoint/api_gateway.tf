data "aws_api_gateway_rest_api" "api" {
  name = var.api_gateway_name
}

resource "aws_api_gateway_resource" "resource_path" {
  rest_api_id = data.aws_api_gateway_rest_api.api.id
  parent_id   = var.resource_parent_id
  path_part   = var.path_part
}

resource "aws_api_gateway_method" "http_method" {
  count         = length(var.handler_method_mapping)
  rest_api_id   = data.aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_path.id
  http_method   = var.handler_method_mapping[count.index].http_method
  authorization = var.authorizer == null ? "NONE" : "CUSTOM"
  authorizer_id = var.authorizer
}

resource "aws_api_gateway_integration" "lambda_integration" {
  count       = length(var.handler_method_mapping)
  rest_api_id = data.aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.http_method[count.index].resource_id
  http_method = aws_api_gateway_method.http_method[count.index].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function[count.index].invoke_arn
}
