# Rate Limiting

Rate limiting is managed in the local `aptible_waf` module. Rate limiting is
configured as a number of requests allowed within a time period. If a client
exceeds this limit, they will be blocked for a period of time. The default limit
is 100 requests per minute.

## Configuration

The rate limit can be configured by setting the `rate_limit_requests` and
`rate_limit_window` variables. The number of requests may be between **10** and
**2,000,000,000**. The window may be one of **60**, **120**, **300**, or
**600**.

> [!TIP]
> You can disable rate limiting by setting `rate_limit_requests` to **0**.
>
> ```hcl
> rate_limit_requests = 0
> ```

For example, the following settings would allow a client to make up to 300
requests every 120 seconds (two minutes):

```hcl
rate_limit_requests = 300
rate_limit_window = 120
```
