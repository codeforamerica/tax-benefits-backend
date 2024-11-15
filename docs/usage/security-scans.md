# Security Scans

On some environments, you may want to allow automated security scanners to
bypass the WAF. This can be done by setting the `allow_security_scans` variable.
Traffic from the CIDRs listed in the `security_scanners` variable will be
allowed.

## Configuration

> [!CAUTION]
> Security scans can result in a performance impact on your application. It is
> recommended to execute these scans outside of peak hours, in accordance with
> any requirements from your project.

By default, security scanners are disabled. When `allow_security_scans` is set
to `true`, the CIDRs for [Detectify] and [SecurityMetrics] are allowed. You can
override the allowed CIDRs by setting the `security_scan_cidrs` variable:

```hcl
allow_security_scans = true
security_scan_cidrs = ["192.168.1.0/22", "10.0.0.0/8"]
```

[detectify]: https://support.detectify.com/support/solutions/articles/48001049001-how-do-i-allow-detectify-to-scan-my-assets
[securitymetrics]: https://www.securitymetrics.com/terms-of-service#abuse
