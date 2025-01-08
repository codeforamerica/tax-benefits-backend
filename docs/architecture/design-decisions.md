# Design Decisions

## Caching policy

Cache tuning is a delicate process of its own. It requires a deep understanding
of the application's behavior and defining rules to ensure only appropriate
requests are cached. Further, you need to ensure that the cache is invalidated
when the data changes and avoid [cache poisoning][cache-poisoning] attacks.

For this reason, we currently use the managed [CachingDisabled][cache-policy]
policy for CloudFront to disable caching entirely. This avoids cache poisoning
without the need to define complex cache rules.

Caching can be a valuable tool to improve performance, and we should revisit
this topic when we have an opportunity to define a caching strategy.

[cache-poisoning]: https://portswigger.net/research/practical-web-cache-poisoning
[cache-policy]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled
