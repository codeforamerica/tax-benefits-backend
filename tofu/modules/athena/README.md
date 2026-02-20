# Athena Module

This module configures Amazon Athena to query data from S3 buckets.

## Features

- Creates an Athena Workgroup with enforced configuration.
- Creates an Athena Database.
- Creates an S3 bucket for storing query results with a lifecycle policy.
- Creates an IAM policy that grants the necessary permissions to query specified S3 buckets and manage Athena results.

## Usage

```hcl
module "athena" {
  source = "../../modules/athena"

  workgroup_name     = "datadog-log-query"
  database_name      = "datadog_logs"
  result_bucket_name = "tax-benefits-athena-results-prod"
  source_bucket_arns = ["arn:aws:s3:::gyr-datadog-log-archive"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| workgroup_name | The name of the Athena workgroup. | `string` | n/a | yes |
| database_name | The name of the Athena database. | `string` | n/a | yes |
| result_bucket_name | The name of the S3 bucket to store Athena results. | `string` | n/a | yes |
| result_retention_days | The number of days to keep Athena results in the S3 bucket. | `number` | `7` | no |
| source_bucket_arns | A list of S3 bucket ARNs that Athena will query data from. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| workgroup_name | The name of the Athena workgroup. |
| database_name | The name of the Athena database. |
| result_bucket | The name of the S3 bucket storing Athena results. |
| athena_policy_arn | The ARN of the IAM policy granting Athena access. |
