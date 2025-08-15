# AWS Textract IAM Configuration Module
# This module provides IAM policies and attachments for AWS Textract access

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Variables are defined in variables.tf

# Data source for AWS managed Textract policies
data "aws_iam_policy" "textract_full_access" {
  count = var.textract_policy_type == "full" ? 1 : 0
  name  = "AmazonTextractFullAccess"
}

data "aws_iam_policy" "textract_read_only" {
  count = var.textract_policy_type == "read-only" ? 1 : 0
  name  = "AmazonTextractReadOnlyAccess"
}

# Attach the appropriate Textract policy to the Lambda role
resource "aws_iam_role_policy_attachment" "textract_permission" {
  role = var.lambda_role_name
  policy_arn = var.textract_policy_type == "full" ? data.aws_iam_policy.textract_full_access[0].arn : data.aws_iam_policy.textract_read_only[0].arn
}

# Outputs are defined in outputs.tf