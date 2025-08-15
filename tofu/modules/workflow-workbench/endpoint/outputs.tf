output "resource_method_integration_configuration_hash" {
  value = sha512(jsonencode([
    aws_api_gateway_resource.resource_path,
    aws_api_gateway_method.http_method,
    aws_api_gateway_integration.lambda_integration,
  ]))
}

output "resource_id" {
  value = aws_api_gateway_resource.resource_path.id
}
