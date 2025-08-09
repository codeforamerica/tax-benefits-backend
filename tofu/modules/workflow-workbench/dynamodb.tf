resource "aws_dynamodb_table" "extracted_data" {
  name     = "${local.name_prefix}-text-extract"
  hash_key = "document_id"

  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "document_id"
    type = "S"
  }

  # Encryption at rest with KMS
  server_side_encryption {
    enabled     = true
    kms_key_arn = local.kms_key_id
  }

  # Point-in-time recovery for production environments
  point_in_time_recovery {
    enabled = var.environment == "production" || var.environment == "staging"
  }

  # Enable deletion protection for non-ephemeral environments
  deletion_protection_enabled = var.ephemeral_suffix == "" && var.environment == "production"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-text-extract"
  })
}