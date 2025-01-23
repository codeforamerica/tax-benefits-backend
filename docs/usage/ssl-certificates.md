# SSL Certificates

The service uses two endpoints for traffic into the application: the CloudFront
distribution used for the [web application firewall][waf] (WAF), and the [origin
endpoint][origin] that routes traffic from CloudFront to the application
containers. Certificates are handled differently for each endpoint.

## CloudFront Distribution

For most environments, the CloudFront distribution uses a managed certificate
from AWS Certificate Manager (ACM). This certificate is automatically renewed
and managed by AWS.

For production endpoints where users will be filing taxes, we must use an
extended validation (EV) certificate. These certificates require additional
verification steps and can not be managed by ACM. Instead, we must import a
certificate that has been issued by another provider (such as IdenTrust).

### Importing a certificate

1. Log into your AWS account console
1. Navigate to the [ACM service][acm-dasboard]
1. Click on the "Import" button

    ![Screenshot of buttons on the ACM service, with an arrow pointing to the
    "Import" button.][acm-import-button]

1. Paste your certificate into the "Certificate body" field
1. Paste the private key into the "Certificate private key" field
1. If you have a certificate chain, paste it into the "Certificate chain" field.
  If your chain includes multiple certificates, paste them in order from the
  root certificate to the end-entity certificate.
1. Set the appropriate `project` and `environment` [tags][tagging]

    > [!WARNING]
    > These tags _must_ be set to the appropriate values in order for the
    > certificate to be found by the infrastructure code. See the [tagging]
    > documentation for more information.

    ![Screenshot of the tags section of the ACM import form, with the project
    and environment tags set to "fyst" and "production"
    respectively.][acm-import-tags]

1. Click "Import certificate" to complete the import

### Using an imported certificate

To use an imported certificate, the configuration for the environment must be
updated. Set the `certificate_imported` variable to `true` and, if the
certificate domain is different from the CloudFront domain, set the
`certificate_domain` variable to the domain of the certificate.

See the `codeforamerica/tofu-modules-aws-cloudfront-waf` module's
[documentation][cloudfront-waf-ssl] for more information on how SSL is
configured for the distribution.

### Updating the distribution with an imported certificate

Whether you're setting up an imported certificate for the first time, or you've
updated the certificate and need to apply the changes, you can [apply the
configuration][applying] for the environment to update the distribution.

## Origin Endpoint

For all environments, the origin endpoint uses a certificate managed by Aptible,
which is automatically renewed and managed by Aptible. This endpoint is not
meant to serve traffic directly to users, and in fact blocks all traffic that
does not come from the CloudFront distribution. For this reason, a managed
certificate is sufficient for these endpoints.

[acm-dashboard]: https://console.aws.amazon.com/acm/home
[acm-import-button]: ../assets/images/acm-import/import-button.png
[acm-import-tags]: ../assets/images/acm-import/tags.png
[applying]: index.md#planning--applying-changes
[cloudfront-waf-ssl]: https://github.com/codeforamerica/tofu-modules-aws-cloudfront-waf#ssl-certificates
[origin]: ../architecture/index.md#origin-endpoint
[tagging]: ../architecture/index.md#tagging
[waf]: ../architecture/index.md#web-application-firewall
