# Origin Verification

Origin verification allows us to verify that requests to our origin endpoints
are coming from CloudFront. This is important to ensure that our origins are not
being accessed directly, bypassing the WAF.

While AWS publishes the IP ranges for CloudFront, it's possible for an attacker
to create their own CloudFront distribution pointed at our origin. To protect
against this, we set a custom header in CloudFront and verify it at the origin.
Any requests without a valid header is rejected.

## Configuration

> [!CAUTION]
> When updating the token value, there will be a brief interruption in service
> while the new token is propagated.
>
> To minimize disruption, this operation should be performed outside peak hours.

The [aptible_waf] module creates a secret in [Secrets Manager][secrets-manager]
with a random value. The value for this secret is then looked up to set the
`x-origin-token` header.

To update the token, update the value of the secret in AWS Secrets Manager,
then [apply] the configuration for the appropriate environment.

The Aptible endpoint for the origin will need to be updated with the new token
value. This currently requires a manual update via the Aptible dashboard.

[apply]: getting-started.md#planning-applying-changes
[aptible_waf]: ../modules/aptible-waf.md
[secrets-manager]: https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html
