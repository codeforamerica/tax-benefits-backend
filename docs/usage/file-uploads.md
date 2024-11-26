# File Uploads

By default, the WAF will block all requests where the body is greater than 8KB
in size. However, this can interfere with file uploads. To allow file uploads,
we can override the provided rule, and create a new rule that exempts requests
with a specific path.

## Configuration

Within your configuration, you can set `allow_gyr_uploads = true`. This will
exempt `*/documents` from the size restrictions. The paths are managed in the
[Aptible WAF module][aptible-waf], in the `gyr_upload_paths` [local
variable][locals].

[aptible-waf]: ../modules/aptible-waf.md
[locals]: https://github.com/codeforamerica/tax-benefits-backend/blob/main/tofu/modules/aptible_waf/local.tf
