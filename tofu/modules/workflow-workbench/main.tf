locals {
  project = var.project
  
  # Resource naming
  name_prefix = var.ephemeral_suffix != "" ? "${var.project}-${var.environment}-${var.ephemeral_suffix}" : "${var.project}-${var.environment}"
  
  # KMS key handling
  kms_key_id = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.encryption[0].arn
  
  # VPC configuration
  vpc_config_enabled = var.vpc_id != null && length(var.private_subnet_ids) > 0
  lambda_security_group_id = local.vpc_config_enabled ? aws_security_group.lambda[0].id : null
  
  # Lambda configuration
  lambda_filename         = var.lambda_package_path
  lambda_source_code_hash = filebase64sha256(local.lambda_filename)
  textract_environment_variables = merge(var.textract_form_adapters_env_var_mapping, {
    SQS_QUEUE_URL = aws_sqs_queue.queue_to_dynamo.url
  })
  
  # Common tags
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}