# ============================================================================
# modules/edge-security/cloudfront — cache policies & ordered behaviors
# ============================================================================

# --- Default cache policy (dynamic API: effectively no caching) ------------
resource "aws_cloudfront_cache_policy" "default" {
  name    = "${local.name}-no-cache"
  comment = "No caching for dynamic API/chat traffic."

  default_ttl = 0
  max_ttl     = 1
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Origin"]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# --- Static asset cache policy (long TTL) ----------------------------------
resource "aws_cloudfront_cache_policy" "static" {
  name    = "${local.name}-static-cache"
  comment = "Long-lived caching for static UI assets."

  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

locals {
  ordered_behaviors = [
    # Static assets — cache hard.
    {
      path_pattern     = "/static/*"
      target_origin_id = local.alb_origin_id
      compress         = true
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cache_policy_id  = aws_cloudfront_cache_policy.static.id
    },
    {
      path_pattern     = "/assets/*"
      target_origin_id = local.alb_origin_id
      compress         = true
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cache_policy_id  = aws_cloudfront_cache_policy.static.id
    },
    # API — never cache, forward everything.
    {
      path_pattern     = "/api/*"
      target_origin_id = local.alb_origin_id
      compress         = true
      allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cache_policy_id  = aws_cloudfront_cache_policy.default.id
    },
  ]
}