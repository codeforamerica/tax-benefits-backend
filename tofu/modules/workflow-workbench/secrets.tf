# Secrets Manager resources with KMS encryption
resource "aws_secretsmanager_secret" "private_key" {
  name                    = "${local.name_prefix}-private-key"
  description             = "Private key for JWT signing"
  kms_key_id              = local.kms_key_id
  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-key"
  })
}

resource "aws_secretsmanager_secret" "public_key" {
  name                    = "${local.name_prefix}-public-key"
  description             = "Public key for JWT verification"
  kms_key_id              = local.kms_key_id
  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-key"
  })
}

resource "aws_secretsmanager_secret" "username" {
  name                    = "${local.name_prefix}-username"
  description             = "Username for authentication"
  kms_key_id              = local.kms_key_id
  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-username"
  })
}

resource "aws_secretsmanager_secret" "password" {
  name                    = "${local.name_prefix}-password"
  description             = "Password hash for authentication"
  kms_key_id              = local.kms_key_id
  recovery_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-password"
  })
}

# Output secret ARNs for reference
output "secret_arns" {
  description = "ARNs of created secrets"
  value = {
    private_key = aws_secretsmanager_secret.private_key.arn
    public_key  = aws_secretsmanager_secret.public_key.arn
    username    = aws_secretsmanager_secret.username.arn
    password    = aws_secretsmanager_secret.password.arn
  }
  sensitive = true
}