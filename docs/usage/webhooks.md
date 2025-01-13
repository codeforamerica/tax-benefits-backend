# Webhooks

External services communicating with the application via webhooks can be rate
limited, or match other rules that would result in the request being blocked by
the WAF. To avoid this, we check requests matching certain paths against a
set of conditions to determine if they should be allowed to bypass the WAF.

> [!CAUTION]
> The WAF is only able to verify these request at a surface level. It is not
> a replacement for proper input validation and security practices in your
> application.

## Anatomy of the rule group

For each WebACL, we create a rule group to contain the rules for the webhooks.
Each webhook gets two rules: one to label the request as a webhook, and another
to check the request against the specific criteria for that webhook.

> [!NOTE]
> Requests to webhooks paths _are not blocked_ if they fail to meet the criteria
> for the webhook. Rather, they continue to be evaluated by the remaining rules
> as normal.

For example, the Twilio webhook for the GetYourRefund prod environment would
result in the following rules:

**gyr-staging-webhooks-twilio-label**

  - **If**: The request matches one of the paths
  - **Then**: Add the label `webhook:twilio` to the request

**gyr-staging-webhooks-twilio**

  - **If**: The request has the label `webhook:twilio`
    - **And**: Contains the `x-twilio-signature` header
  - **Then**: Allow the request

## Overrides for specific webhooks

### Mailgun

Mailgun webhooks can be rate limited or blocked due to their size, such as with
large incoming emails.

Paths:

 - `/incoming_emails`
 - `/outgoing_email_status`

Criteria:

  - The request must include basic authentication

### OmniAuth

The OmniAuth callback is used to authenticate users via oauth. The callback's
source is the user's browser, and legitimate traffic should not run into rate
limiting or other rules. As a result, no special rules are applied.

Paths:

  - `/users/omniauth_callbacks`

### Twilio

With high volumes, Twilio can easily run into rate limiting.

Paths:

  - `/incoming_text_messages`
  - `/outbound_calls/:id`
  - `/outbound_calls/connect/:id`
  - `/outgoing_text_messages/:id`
  - `/webhooks/twilio/update_status/:id`

Criteria:

  - The request must include the `x-twilio-signature` header
