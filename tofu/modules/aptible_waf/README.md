# Aptible WAF Module

This module creates the necessary resources to deploy a Web Application Firewall
(WAF) for use with Aptible. This is done through a global [CloudFront
distribution][distribution] (without caching) with an attached [WAF ACL][acl],
and an Aptible [managed endpoint][managed-endpoint] that only allows traffic
from the CloudFront distribution.

## Usage

Add this module to your `main.tf` (or appropriate) file and configure the inputs
to match your desired configuration. For example, to set up a new WAF for a new
demo environment, you may use something like the following:

```hcl
module "aptible_waf" {
  source = "../../modules/aptible_waf"

  project             = "new-tax-project"
  environment         = "demo"
  domain              = "tax-project.org"
  log_bucket          = module.logging.bucket_domain_name
  log_group           = module.logging.log_groups["waf"]
  aptible_environment = "vita-min-demo"
  aptible_app_id      = 12345
  secrets_key_arn     = module.secrets.kms_key_arn
}
```

Make sure you run `tofu init` after adding the module to your configuration,
then plan your configuration to see the changes that would be applied:

```bash
tofu init
tofu plan
```

## Rules

> [!NOTE]
> These rules are managed by the `cloudfront_waf` module. Review the
> [documentation][cloudfront-waf] for this module for the most up to date
> information.

The WAF is configured with the following managed rules groups. The priorities of
these rules are spaced out to allow for custom rules to be inserted between.

| Rule Group Name                                       | Priority | Description                                           |
|-------------------------------------------------------|----------|-------------------------------------------------------|
| [AWSManagedRulesAmazonIpReputationList][rules-ip-rep] | 200      | Protects against IP addresses with a poor reputation. |
| [AWSManagedRulesCommonRuleSet][rules-common]          | 300      | Protects against common threats.                      |
| [AWSManagedRulesKnownBadInputsRuleSet][rules-inputs]  | 400      | Protects against known bad inputs.                    |
| [AWSManagedRulesSQLiRuleSet][rules-sqli]              | 500      | Protects against SQL injection attacks.               |

## Inputs

| Name                 | Description                                                                                                | Type           | Default                                                    | Required |
|----------------------|------------------------------------------------------------------------------------------------------------|----------------|------------------------------------------------------------|----------|
| aptible_app_id       | Id of the Aptible app to attach the WAF to.                                                                | `number`       | n/a                                                        | yes      |
| aptible_environment  | Name of the Aptible environment to attach the WAF to.                                                      | `string`       | n/a                                                        | yes      |
| domain               | Primary domain for the distribution. The hosted zone for this domain should be in the same account.        | `string`       | n/a                                                        | yes      |
| log_bucket           | Domain name of the S3 bucket to send logs to.                                                              | `string`       | n/a                                                        | yes      |
| log_group            | CloudWatch log group to send WAF logs to.                                                                  | `string`       | n/a                                                        | yes      |
| project              | Project that these resources are supporting.                                                               | `string`       | n/a                                                        | yes      |
| secrets_key_arn      | ARN of the KMS key for secrets. This will be used to store and reference the origin token.                 | `string`       | n/a                                                        | yes      |
| allow_gyr_uploads    | Exempt GetYourRefund upload paths from body size restrictions.                                             | `bool`         | `false`                                                    | no       |
| allow_security_scans | Allow security scanners to bypass the WAF.                                                                 | `bool`         | `false`                                                    | no       |
| environment          | The environment for the deployment.                                                                        | `string`       | `"dev"`                                                    | no       |
| passive              | Enable passive mode for the WAF, counting all requests rather than blocking.                               | `bool`         | `false`                                                    | no       |
| rate_limit_requests  | Number of requests allowed in the rate limit window. Minimum of 10, or set to 0 to disable rate limiting.  | `number`       | `100`                                                      | no       |
| rate_limit_window    | Time window, in seconds, for the rate limit. Options are: 60, 120, 300, 600                                | `number`       | `60`                                                       | no       |
| security_scan_cidrs  | CIDRs for security scanners to allow through the WAF. Defaults to [Detectify] and [SecurityMetrics] CIDRs. | `list(string)` | `["52.17.9.21/32", "52.17.98.131/32", "162.211.152.0/24"]` | no       |
| subdomain            | Subdomain for the distribution. Defaults to the environment.                                               | `string`       | n/a                                                        | no       |

[acl]: https://docs.aws.amazon.com/waf/latest/APIReference/API_WebACL.html
[cloudfront-waf]: https://github.com/codeforamerica/tofu-modules-aws-cloudfront-waf
[detectify]: https://support.detectify.com/support/solutions/articles/48001049001-how-do-i-allow-detectify-to-scan-my-assets
[distribution]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-working-with.html
[managed-endpoint]: https://www.aptible.com/docs/core-concepts/apps/connecting-to-apps/app-endpoints/https-endpoints/overview
[rules-common]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-crs
[rules-inputs]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-known-bad-inputs
[rules-ip-rep]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-ip-rep.html#aws-managed-rule-groups-ip-rep-amazon
[rules-sqli]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-sql-db
[securitymetrics]: https://www.securitymetrics.com/terms-of-service#abuse
