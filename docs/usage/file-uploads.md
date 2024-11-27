# File Uploads

By default, the WAF will block all requests where the body is greater than 8KB
in size. However, this can interfere with file uploads. Additionally, random
characters in the file metadata can trigger cross-site scripting (XSS) and SQL
injection rules. To allow file uploads, we can override the provided rules, and
create a new rule that exempts requests with a specific path.

> [!NOTE]
> For more information on how file uploads are handled by the WAF, see the
> [upload_paths] documentation of the
> [`codeforamerica/tofu-modules-aws-cloudfront-waf`][cloudfront-waf] module.

## Configuration

Within your configuration, you can set `allow_gyr_uploads = true`. This will
exempt `*/documents` from the size restrictions. The paths are managed in the
[Aptible WAF module][aptible-waf], in the `gyr_upload_paths` [local
variable][locals].

[aptible-waf]: ../modules/aptible-waf.md
[cloudfront-waf]: https://github.com/codeforamerica/tofu-modules-aws-cloudfront-waf
[locals]: https://github.com/codeforamerica/tax-benefits-backend/blob/main/tofu/modules/aptible_waf/local.tf
[upload_paths]: https://github.com/codeforamerica/tofu-modules-aws-cloudfront-waf#upload_paths
