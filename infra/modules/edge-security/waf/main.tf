# ============================================================================
# modules/edge-security/waf — web ACL, IP sets, logging
# ============================================================================

locals {
  name = "${var.project}-${var.environment}-${lower(var.scope)}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "edge-security/waf"
    Scope       = var.scope
    ManagedBy   = "terraform"
  })
}

# --- IP sets ----------------------------------------------------------------
resource "aws_wafv2_ip_set" "allowlist" {
  count              = length(var.ip_allowlist) > 0 ? 1 : 0
  name               = "${local.name}-allowlist"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_allowlist
  tags               = local.tags
}

resource "aws_wafv2_ip_set" "blocklist" {
  count              = length(var.ip_blocklist) > 0 ? 1 : 0
  name               = "${local.name}-blocklist"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_blocklist
  tags               = local.tags
}

# --- Web ACL ----------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = "${local.name}-web-acl"
  description = "Edge protection for ${var.project} (${var.scope})."
  scope       = var.scope

  default_action {
    allow {}
  }

  # Rules are composed from the other files via the `rule` dynamic blocks
  # below. Order matters: lower priority number = evaluated first.

  # 1. IP allowlist (highest priority — always allow)
  dynamic "rule" {
    for_each = length(var.ip_allowlist) > 0 ? [1] : []
    content {
      name     = "ip-allowlist"
      priority = 0
      action {
        allow {}
      }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowlist[0].arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name}-ip-allowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  # 2. IP blocklist
  dynamic "rule" {
    for_each = length(var.ip_blocklist) > 0 ? [1] : []
    content {
      name     = "ip-blocklist"
      priority = 1
      action {
        block {}
      }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocklist[0].arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name}-ip-blocklist"
        sampled_requests_enabled   = true
      }
    }
  }

  # 3. Geo blocking / allowlisting
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      name     = "geo-block"
      priority = 2
      action {
        block {}
      }
      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name}-geo-block"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.allowed_countries) > 0 ? [1] : []
    content {
      name     = "geo-allowlist"
      priority = 3
      action {
        block {}
      }
      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = var.allowed_countries
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name}-geo-allowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  # 4. Rate limiting rules (from rate-limiting.tf via local.rate_limit_rules)
  dynamic "rule" {
    for_each = local.rate_limit_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        block {}
      }
      statement {
        rate_based_statement {
          limit              = rule.value.limit
          aggregate_key_type = "IP"

          dynamic "scope_down_statement" {
            for_each = rule.value.path_prefix != null ? [1] : []
            content {
              byte_match_statement {
                positional_constraint = "STARTS_WITH"
                search_string         = rule.value.path_prefix
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  # 5. AWS managed rule groups (from managed-rule-groups.tf)
  dynamic "rule" {
    for_each = local.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags, { Name = "${local.name}-web-acl" })
}

# --- Logging ----------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf" {
  count             = var.enable_logging ? 1 : 0
  name              = "aws-waf-logs-${local.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.enable_logging ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}