locals {
  subdomain           = var.subdomain != "" ? var.subdomain : var.environment
  gyr_upload_capacity = 69
  gyr_upload_paths = [
    {
      constraint = "ENDS_WITH"
      path       = "/documents"
    },
    {
      constraint = "CONTAINS"
      path       = "/documents/"
    },
    {
      constraint = "ENDS_WITH"
      path       = "/portal/upload-documents"
    },
    {
      constraint = "ENDS_WITH"
      path       = "/messages"
    },
    {
      constraint = "ENDS_WITH"
      path       = "/outgoing_emails"
    },
    # These last two don't include file uploads, but they can be large enough to
    # trigger the size limit rule.
    {
      constraint = "STARTS_WITH"
      path       = "/en/hub/state_routings/"
    },
    {
      constraint = "STARTS_WITH"
      path       = "/en/hub/clients/"
    },
  ]

  webhooks = {
    mailgun = {
      paths = [
        {
          constraint = "EXACTLY"
          path       = "/incoming_emails"
        },
        {
          constraint = "EXACTLY"
          path       = "/outgoing_email_status"
        }
      ]
      criteria = [
        {
          type       = "byte"
          constraint = "STARTS_WITH"
          field      = "header"
          name       = "authorization"
          value      = "Basic "
        }
      ]
      action = "allow"
    }
    twilio = {
      paths = [
        {
          constraint = "EXACTLY"
          path       = "/incoming_text_messages"
        },
        {
          constraint = "STARTS_WITH"
          path       = "/outbound_calls/"
        },
        {
          constraint = "STARTS_WITH"
          path       = "/outgoing_text_messages/"
        },
        {
          constraint = "STARTS_WITH"
          path       = "/webhooks/twilio/update_status/"
        }
      ]
      criteria = [
        {
          type       = "size"
          constraint = "GT"
          field      = "header"
          name       = "x-twilio-signature"
          value      = "0"
        }
      ]
      action = "allow"
    }
  }
}
