locals {
  subdomain = var.subdomain != "" ? var.subdomain : var.environment
  gyr_upload_paths = [{
    constraint = "ENDS_WITH"
    path       = "/documents"
  }]

  webhooks = {
    mailgun = {
      paths = [{
          constraint = "EXACTLY"
          path      = "/incoming_emails"
        },
        {
          constraint = "EXACTLY"
          path      = "/outgoing_email_status"
      }]
      criteria = [{
        type       = "byte"
        constraint = "STARTS_WITH"
        field      = "header"
        name       = "authorization"
        value = "Basic "
      }]
      action = "allow"
    }
    twilio = {
      paths = [{
          constraint = "EXACTLY"
          path      = "/incoming_text_messages"
        },
        {
          constraint = "STARTS_WITH"
          path      = "/outbound_calls/"
        },
        {
          constraint = "STARTS_WITH"
          path      = "/outgoing_text_messages/"
        },
        {
          constraint = "STARTS_WITH"
          path      = "/webhooks/twilio/update_status/"
      }]
      criteria = [{
        type       = "size"
        constraint = "GT"
        field      = "header"
        name       = "x-twilio-signature"
        value      = "0"
      }]
      action = "allow"
    }
  }
}
