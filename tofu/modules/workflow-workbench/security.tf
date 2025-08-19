resource "aws_security_group" "lambda" {
  count = local.vpc_config_enabled ? 1 : 0

  name_prefix = "${local.name_prefix}-lambda-"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lambda_egress_https" {
  count = local.vpc_config_enabled ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda[0].id
  description       = "Allow HTTPS outbound for AWS API calls"
}

resource "aws_security_group_rule" "lambda_egress_dns" {
  count = local.vpc_config_enabled ? 1 : 0

  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda[0].id
  description       = "Allow DNS resolution"
}

# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoints" {
  count = local.vpc_config_enabled ? 1 : 0

  name_prefix = "${local.name_prefix}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vpc_endpoints_ingress" {
  count = local.vpc_config_enabled ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda[0].id
  security_group_id        = aws_security_group.vpc_endpoints[0].id
  description              = "Allow Lambda functions to access VPC endpoints"
}