# VPC Endpoints for AWS services (reduces costs and improves security)
# Only created when VPC configuration is enabled

locals {
  # Required VPC endpoints for the application
  vpc_endpoints = {
    s3 = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
      type         = "Gateway"
    }
    dynamodb = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
      type         = "Gateway"
    }
    secretsmanager = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
      type         = "Interface"
    }
    sqs = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.sqs"
      type         = "Interface"
    }
    textract = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.textract"
      type         = "Interface"
    }
    kms = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.kms"
      type         = "Interface"
    }
    logs = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.logs"
      type         = "Interface"
    }
    # For Session Manager support
    ssm = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"
      type         = "Interface"
    }
    ssmmessages = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
      type         = "Interface"
    }
    ec2messages = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
      type         = "Interface"
    }
  }
}

# Gateway endpoints (S3 and DynamoDB)
resource "aws_vpc_endpoint" "gateway" {
  for_each = local.vpc_config_enabled ? {
    for k, v in local.vpc_endpoints : k => v
    if v.type == "Gateway"
  } : {}

  vpc_id       = var.vpc_id
  service_name = each.value.service_name

  route_table_ids = data.aws_route_tables.private.ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-endpoint"
  })
}

# Interface endpoints (all others)
resource "aws_vpc_endpoint" "interface" {
  for_each = local.vpc_config_enabled ? {
    for k, v in local.vpc_endpoints : k => v
    if v.type == "Interface"
  } : {}

  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-endpoint"
  })
}

# Data source to get private route tables
data "aws_route_tables" "private" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Type"
    values = ["private", "Private"]
  }
}

# S3 VPC Endpoint Policy
resource "aws_vpc_endpoint_policy" "s3" {
  count = local.vpc_config_enabled && contains(keys(local.vpc_endpoints), "s3") ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.gateway["s3"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# DynamoDB VPC Endpoint Policy
resource "aws_vpc_endpoint_policy" "dynamodb" {
  count = local.vpc_config_enabled && contains(keys(local.vpc_endpoints), "dynamodb") ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.gateway["dynamodb"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.extracted_data.arn,
          "${aws_dynamodb_table.extracted_data.arn}/*"
        ]
      }
    ]
  })
}