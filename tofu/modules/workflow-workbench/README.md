# Workflow Workbench Infrastructure Module

This OpenTofu/Terraform module provisions the infrastructure for the Workflow Workbench Document Extractor application with AWS compliance requirements.

## Features

- **Security & Compliance**:
  - KMS encryption for all data at rest
  - SSL/TLS enforcement on all endpoints
  - Least-privilege IAM policies
  - VPC support with private subnets for Lambda functions
  - WAF protection for CloudFront and API Gateway
  - CloudWatch logging with encryption and retention policies

- **Infrastructure Components**:
  - S3 buckets for document storage and static website hosting
  - CloudFront distribution with Origin Access Identity
  - API Gateway with Lambda integration
  - Lambda functions for document processing
  - DynamoDB for extracted data storage
  - SQS for asynchronous processing
  - Secrets Manager for sensitive configuration

## Usage

```hcl
module "workflow-workbench" {
  source = "../../modules/workflow-workbench"

  environment         = "staging"
  domain              = "staging.workflow-workbench.example.com"
  lambda_package_path = "/path/to/lambda.zip"
  ui_dist_path        = "/path/to/ui/dist"
  
  # Optional: Use existing VPC
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # Optional: Use existing KMS key
  kms_key_arn = module.kms.key_arn
  
  enable_waf         = true
  log_retention_days = 30
  
  allowed_origins = [
    "https://staging.workflow-workbench.example.com"
  ]
  
  tags = {
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}
```

## Required Inputs

| Name | Description | Type |
|------|-------------|------|
| `environment` | Environment name (e.g., dev, staging, production) | `string` |
| `domain` | Domain name for the application | `string` |
| `lambda_package_path` | Path to the Lambda deployment package ZIP file | `string` |
| `ui_dist_path` | Path to the UI distribution files directory | `string` |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID where resources will be deployed | `string` | `null` |
| `private_subnet_ids` | List of private subnet IDs for Lambda | `list(string)` | `[]` |
| `public_subnet_ids` | List of public subnet IDs | `list(string)` | `[]` |
| `kms_key_arn` | KMS key ARN for encryption | `string` | `null` |
| `log_retention_days` | CloudWatch Logs retention in days | `number` | `30` |
| `enable_waf` | Enable WAF protection | `bool` | `true` |
| `allowed_origins` | Allowed origins for CORS | `list(string)` | `["*"]` |
| `allowed_ips` | IP addresses allowed to access | `list(string)` | `[]` |
| `allowed_countries` | Countries allowed for geo-restriction | `list(string)` | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `cloudfront_distribution_id` | CloudFront distribution ID |
| `cloudfront_domain_name` | CloudFront distribution domain name |
| `api_gateway_url` | API Gateway invoke URL |
| `document_storage_bucket` | S3 bucket for document storage |
| `website_bucket` | S3 bucket for website hosting |
| `dynamodb_table_name` | DynamoDB table name |
| `lambda_functions` | Map of Lambda function names |

## Deployment Process

### 1. Build Artifacts

The application code must be built before deployment:

```bash
# Build Lambda package (from app repository)
cd app/backend
uv run build.py
# Creates dist/lambda.zip

# Build UI distribution (from app repository)
cd app/ui
npm install
npm run build
# Creates dist/ directory
```

### 2. Deploy Infrastructure

```bash
cd infrastructure/tofu/config/staging.workflow-workbench.fileyourstatetaxes.org

# Initialize
tofu init

# Plan with artifact paths
tofu plan \
  -var="lambda_package_path=/path/to/lambda.zip" \
  -var="ui_dist_path=/path/to/ui/dist"

# Apply
tofu apply \
  -var="lambda_package_path=/path/to/lambda.zip" \
  -var="ui_dist_path=/path/to/ui/dist"
```

### 3. CI/CD Integration

The GitHub Actions workflows handle the build and deployment process:

1. **PR Checks** (`workflow-workbench-pr-check.yml`):
   - Runs on PRs affecting infrastructure code
   - Validates formatting and runs security scans
   - Creates a plan and posts it as a PR comment

2. **Staging Deployment** (`workflow-workbench-deploy.yml`):
   - Runs on merge to main branch
   - Downloads artifacts from app repository
   - Deploys to staging environment
   - Invalidates CloudFront cache

3. **PR Preview Environments** (`workflow-workbench-pr-preview.yml`):
   - Triggered by `deploy-preview` label
   - Creates ephemeral environment for testing
   - Automatically cleaned up on PR close

## Security Considerations

1. **Secrets Management**:
   - Generate RSA key pairs for JWT authentication
   - Store in AWS Secrets Manager before deployment
   - Lambda functions will access via IAM roles

2. **Network Security**:
   - Lambda functions can be deployed in VPC with private subnets
   - VPC endpoints reduce costs and improve security
   - Security groups restrict access to minimum required

3. **Data Encryption**:
   - All data encrypted at rest using KMS
   - SSL/TLS enforced on all endpoints
   - CloudWatch logs encrypted

## Compliance Notes

This module implements AWS compliance requirements including:
- S3 bucket versioning and encryption
- CloudWatch log retention and encryption
- Least-privilege IAM policies
- VPC endpoints for AWS service access
- WAF protection for web applications
- Lifecycle policies for data retention

## Troubleshooting

### Common Issues

1. **Lambda package not found**:
   - Ensure the Lambda ZIP file exists at the specified path
   - Check that the build process completed successfully

2. **UI files not deploying**:
   - Verify the UI build created the dist directory
   - Check file permissions on the dist directory

3. **API Gateway errors**:
   - Check Lambda function logs in CloudWatch
   - Verify IAM roles have necessary permissions
   - Ensure secrets are properly configured

### Debug Commands

```bash
# Check Lambda function logs
aws logs tail /aws/lambda/workflow-workbench-staging-text-extract

# Test API endpoint
curl https://your-cloudfront-domain/api/health

# Check S3 bucket contents
aws s3 ls s3://workflow-workbench-staging-documents-ACCOUNTID/
```