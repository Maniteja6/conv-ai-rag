# ============================================================================
# modules/networking/route53 — hosted zones & primary records
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "networking/route53"
    ManagedBy   = "terraform"
  })

  # CloudFront alias takes precedence over ALB when both are supplied.
  apex_alias_target = var.cloudfront_domain_name != null ? {
    name    = var.cloudfront_domain_name
    zone_id = var.cloudfront_zone_id
    } : {
    name    = var.alb_dns_name
    zone_id = var.alb_zone_id
  }
}

# --- Public hosted zone -----------------------------------------------------
resource "aws_route53_zone" "public" {
  count = var.create_public_zone ? 1 : 0
  name  = var.domain_name
  tags  = merge(local.tags, { Name = "${local.name}-public-zone" })
}

# --- Private hosted zone (internal service discovery) ----------------------
resource "aws_route53_zone" "private" {
  count = var.create_private_zone ? 1 : 0
  name  = "internal.${var.domain_name}"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(local.tags, { Name = "${local.name}-private-zone" })
}

# --- Apex A/AAAA alias to CloudFront or ALB --------------------------------
resource "aws_route53_record" "apex_a" {
  count   = var.create_public_zone && local.apex_alias_target.name != null ? 1 : 0
  zone_id = aws_route53_zone.public[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = local.apex_alias_target.name
    zone_id                = local.apex_alias_target.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apex_aaaa" {
  count   = var.create_public_zone && local.apex_alias_target.name != null ? 1 : 0
  zone_id = aws_route53_zone.public[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = local.apex_alias_target.name
    zone_id                = local.apex_alias_target.zone_id
    evaluate_target_health = true
  }
}

# --- www CNAME --------------------------------------------------------------
resource "aws_route53_record" "www" {
  count   = var.create_public_zone ? 1 : 0
  zone_id = aws_route53_zone.public[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}