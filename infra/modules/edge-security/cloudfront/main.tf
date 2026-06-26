# ============================================================================
# modules/edge-security/cloudfront — distribution
# Fronts the ALB for cacheable/UI/REST traffic. WebSocket (/ws/*) traffic is
# NOT served here — clients connect to the ALB directly (CloudFront cannot
# proxy raw WebSockets). See ARCHITECTURE.md data-flow.
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "edge-security/cloudfront"
    ManagedBy   = "terraform"
  })
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name} edge distribution"
  aliases             = var.aliases
  price_class         = var.price_class
  default_root_object = var.default_root_object
  web_acl_id          = var.web_acl_arn
  http_version        = "http2and3"

  # origins + ordered_cache_behavior + default_cache_behavior are defined in
  # origin-config.tf and cache-behaviors.tf via locals consumed below.

  dynamic "origin" {
    for_each = local.origins
    content {
      origin_id           = origin.value.origin_id
      domain_name         = origin.value.domain_name
      connection_attempts = 3
      connection_timeout  = 10

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = origin.value.protocol_policy
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_read_timeout    = origin.value.read_timeout
        origin_keepalive_timeout = 60
      }

      dynamic "custom_header" {
        for_each = var.custom_origin_header_secret != null ? [1] : []
        content {
          name  = "X-Origin-Verify"
          value = var.custom_origin_header_secret
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.default_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.default.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.default.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.ordered_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = "redirect-to-https"
      compress               = ordered_cache_behavior.value.compress
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ["GET", "HEAD"]

      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = aws_cloudfront_origin_request_policy.default.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  dynamic "logging_config" {
    for_each = var.logging_bucket_domain != null ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logging_bucket_domain
      prefix          = "cloudfront/${local.name}/"
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-cf" })
}