resource "aws_lambda_function" "function" {
  count         = length(var.handler_method_mapping)
  function_name = "${var.resource_prefix}-${var.handler_method_mapping[count.index].name}"

  filename         = var.handler_method_mapping[count.index].handler_file_path
  source_code_hash = filebase64sha256(var.handler_method_mapping[count.index].handler_file_path)

  handler = var.handler_method_mapping[count.index].handler_package

  memory_size                    = 256
  timeout                        = 30
  runtime                        = "python3.13"
  reserved_concurrent_executions = -1
  publish                        = true

  architectures = [var.lambda_arch]

  kms_key_arn = var.kms_key_arn

  role = var.lambda_execution_role

  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_permission" "api_gateway" {
  count         = length(var.handler_method_mapping)
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${data.aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_provisioned_concurrency_config" "api_function_concurrency" {
  count                             = length(var.handler_method_mapping)
  function_name                     = aws_lambda_function.function[count.index].function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.function[count.index].version
}
