locals {
  s3_origin_id          = "website-in-s3"
  api_gateway_origin_id = "api-in-gateway"
  api_prefix_path       = "api"
}

# CloudFront Distribution with compliance features
resource "aws_cloudfront_distribution" "website" {
  enabled = true
  comment = "${var.project} ${var.environment} website"

  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = var.environment == "production" ? "PriceClass_All" : "PriceClass_100"

  # Custom domain configuration
  aliases = var.domain != "" ? [var.domain] : []

  # S3 Website Origin with OAI
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }

    origin_shield {
      enabled              = var.environment == "production"
      origin_shield_region = data.aws_region.current.name
    }
  }

  # API Gateway Origin
  origin {
    domain_name = split("/", aws_api_gateway_stage.stage.invoke_url)[2]
    origin_id   = local.api_gateway_origin_id
    origin_path = "/${aws_api_gateway_stage.stage.stage_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-api-key"
      value = var.api_key != "" ? var.api_key : "placeholder"
    }
  }

  # Default behavior for static content
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 86400   # 1 day
    max_ttl     = 2592000 # 30 days
    compress    = true

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
    }

    # Response headers policy for security
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # API behavior
  ordered_cache_behavior {
    path_pattern           = "/${local.api_prefix_path}/*"
    target_origin_id       = local.api_gateway_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader

    compress = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }

    # Response headers policy for API
    response_headers_policy_id = aws_cloudfront_response_headers_policy.api_headers.id
  }

  # Custom error pages
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Logging
  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  # WAF Web ACL
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null

  viewer_certificate {
    cloudfront_default_certificate = var.domain == ""
    acm_certificate_arn            = var.domain != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.domain != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.allowed_countries) > 0 ? "whitelist" : "none"
      locations        = var.allowed_countries
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudfront"
  })

  depends_on = [
    aws_s3_bucket_policy.website,
    aws_api_gateway_deployment.deployment
  ]
}

# CloudFront Function for URI rewriting
resource "aws_cloudfront_function" "rewrite_uri" {
  name    = "${local.name_prefix}-rewrite-request"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite /api/* to /* for API Gateway"
  code    = <<-EOF
function handler(event) {
  var request = event.request;
  request.uri = request.uri.replace(/^\/${local.api_prefix_path}\//, "/");
  return request;
}
EOF
}

# Security Headers Response Policy
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${local.name_prefix}-security-headers"
  comment = "Security headers for ${var.project}"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.amazonaws.com"
      override                = true
    }
  }

  custom_headers_config {
    items {
      header   = "X-Environment"
      value    = var.environment
      override = false
    }

    items {
      header   = "Permissions-Policy"
      value    = "geolocation=(), microphone=(), camera=()"
      override = true
    }
  }
}

# API Headers Response Policy
resource "aws_cloudfront_response_headers_policy" "api_headers" {
  name    = "${local.name_prefix}-api-headers"
  comment = "API headers for ${var.project}"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
    }

    access_control_allow_origins {
      items = var.allowed_origins
    }

    access_control_max_age_sec = 86400
    origin_override            = true
  }
}

# Outputs for DNS configuration
output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}