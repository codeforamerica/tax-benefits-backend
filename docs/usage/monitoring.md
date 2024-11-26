# Monitoring

The system is monitored using DataDog, which combines logs and metrics from
the various components of the service to provide a comprehensive view of the
system's health.

## Web Application Firewall

> [!NOTE]
> Rate limited requests are included in the count of blocked requests provided
> by AWS. This dashboard makes a conscious effort to separate the two for
> clarity and ease of management.

The WAF can be monitored through the [Web Application Firewall
dashboard][datadog-waf] in Datadog.

### Summary

At the top of the dashboard, you will see a summary of the WAF's activity over
the last day. This includes the number of requests that were allowed, blocked,
rate limited, or counted.

![Top section of a dashboard with blocks for the total number of requests, and
the percentages of allowed, blocked, rate limited, and counted requests. Below
the blocks is a stacked bar graph showing each of these request actions over
time.][img-waf-summary]

You can select one or more Web ACLs (the WAF's ruleset) to filter the dashboard.
The ACLs include a project name and environment, which can help you identify
which application is being monitored. Additionally, you can adjust the time
range to see activity over a longer period.

### Configuration

The dashboard is deployed using the `datadog` config, and managed by the
[`codeforamerica/tofu-modules-datadog-waf`][datadog-waf] module. See this
configuration and the module's documentation for more details on how to customize
the dashboard.

### Blocked requests

Here, you'll find a breakdown of the requests that were blocked by the WAF. This
includes the top blocked IPs, the number of requests blocked by each rule or
attack, and a timeline of blocked requests.

![Blocked Requests section of a dashboard, with blocks for blocked requests over
time and top blocked IPs, by attacked, by managed rule, and by rule. Below is a
list of relevant log messages.][img-waf-blocked]

This section is useful to identify patterns in blocked requests, such as a
specific IP address that is repeatedly blocked, or a rule that is blocking a
large number of requests. The log entries can provide additional context for
blocked requests, and are a good starting point for further investigation.

### Rate limiting

> [!TIP]
> If you're experiencing issues with legitimate traffic being rate limited, see
> the [rate limiting][rate-limiting] documentation for details on updating the
> rate limit.

Although rate limited requests are blocked, we separate them from the blocked
requests to provide a clearer view of the WAF's activity. This section shows the
number of rate limited requests over time, and the top rate limited IPs.

![Rate Limiting section of a dashboard, with blocks showing rate limited
requests over time, top rate limited IPs, and relevant log
entries.][img-waf-rate]

The log entries include more details about the rate limited requests. This
includes the parameters for rate limiting, which can be found under the
`rateBasedRuleList` field. This does not necessarily represent the current
parameters, but those at the time the request was received.

### Counted requests

Counted requests are requests that matched a rule in the WAF, but where that
rule overridden to count the request rather than block it. This is useful for
monitoring traffic without affecting the application, and can be used to
fine-tune the WAF rules before enforcing them.

![Counted Requests section of a dashboard, with blocks showing counted requests
over time, requests counted by rule, and relevant log entries.][img-waf-counted]

These requests could also have been caught by a rule that is intentionally
overridden. One example is the `SizeRestrictions_BODY` rule, which is used to
block requests with large bodies. This rule is overridden to count requests
rather than block them, and a separate rule blocks these requests based on their
path to allow for [file uploads][file-uploads].

[datadog-waf]: https://github.com/codeforamerica/tofu-modules-datadog-waf
[file-uploads]: file-uploads.md
[img-waf-blocked]: ../assets/images/waf-dashboard/blocked.png
[img-waf-counted]: ../assets/images/waf-dashboard/counted.png
[img-waf-rate]: ../assets/images/waf-dashboard/rate-limiting.png
[img-waf-summary]: ../assets/images/waf-dashboard/summary.png
[rate-limiting]: rate-limiting.md
[waf-dashboard]: https://app.datadoghq.com/dashboard/cch-jdh-ek6/web-application-firewall-waf
