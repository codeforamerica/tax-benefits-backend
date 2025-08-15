# AWS Textract IAM Module

This OpenTofu/Terraform module manages IAM permissions for AWS Textract access.

## Features

- Configurable access levels (full or read-only)
- Attaches AWS managed policies for Textract
- Designed for Lambda functions that need Textract access

## Usage

```hcl
module "textract_permissions" {
  source = "../../modules/textract"
  
  lambda_role_name     = aws_iam_role.lambda_execution.name
  textract_policy_type = "full"  # or "read-only"
  
  tags = {
    Environment = "production"
    Application = "document-processor"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| lambda_role_name | The name of the Lambda IAM role to attach Textract permissions to | `string` | n/a | yes |
| textract_policy_type | Type of Textract access policy to attach (full or read-only) | `string` | `"full"` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| textract_policy_arn | The ARN of the attached Textract policy |
| policy_attachment_id | The unique ID for the policy attachment |
| policy_type | The type of Textract policy attached (full or read-only) |

## AWS Managed Policies Used

- **Full Access**: `AmazonTextractFullAccess` - Provides full access to Amazon Textract
- **Read Only**: `AmazonTextractReadOnlyAccess` - Provides read-only access to Amazon Textract

## Example with Lambda Function

```hcl
# Create Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name = "my-lambda-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach Textract permissions
module "textract_permissions" {
  source = "../../modules/textract"
  
  lambda_role_name     = aws_iam_role.lambda_execution.name
  textract_policy_type = "full"
}

# Create Lambda function
resource "aws_lambda_function" "document_processor" {
  function_name = "document-processor"
  role         = aws_iam_role.lambda_execution.arn
  # ... other configuration
}
```