# ============================================================================
# modules/edge-security/cloudfront — origins
# ============================================================================

locals {
  alb_origin_id     = "alb-${local.name}"
  default_origin_id = local.alb_origin_id

  origins = [
    {
      origin_id       = local.alb_origin_id
      domain_name     = var.alb_domain_name
      protocol_policy = "https-only"
      read_timeout    = 60 # REST + streaming responses from agent-orchestrator
    },
  ]
}

# --- Origin request policy: forward what the app needs ---------------------
resource "aws_cloudfront_origin_request_policy" "default" {
  name    = "${local.name}-origin-req"
  comment = "Forward auth, host, and query strings to origin."

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewerAndWhitelistCloudFront"
    headers {
      items = ["CloudFront-Viewer-Country", "CloudFront-Is-Mobile-Viewer"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# --- Response headers policy: security headers -----------------------------
resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${local.name}-security-headers"
  comment = "HSTS, CSP, and anti-clickjacking headers."

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
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
  }

  custom_headers_config {
    items {
      header   = "X-Permitted-Cross-Domain-Policies"
      value    = "none"
      override = true
    }
  }
}