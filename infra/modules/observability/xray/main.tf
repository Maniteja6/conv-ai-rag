# ============================================================================
# modules/observability/xray — sampling rules + encryption
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "observability/xray"
    ManagedBy   = "terraform"
  })
}

# --- Encryption config (account-level; KMS-encrypt trace data) -------------
resource "aws_xray_encryption_config" "this" {
  count  = var.kms_key_arn != null ? 1 : 0
  type   = "KMS"
  key_id = var.kms_key_arn
}

# --- Default sampling rule --------------------------------------------------
resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${local.name}-default"
  priority       = 10000
  version        = 1
  reservoir_size = var.reservoir_size
  fixed_rate     = var.sampling_rate
  host           = "*"
  http_method    = "*"
  url_path       = "*"
  service_name   = "*"
  service_type   = "*"
  resource_arn   = "*"

  tags = local.tags
}

# --- High-value path rule (trace chat flows more aggressively) -------------
resource "aws_xray_sampling_rule" "high_value" {
  for_each = toset(var.high_value_paths)

  rule_name      = "${local.name}-${replace(trimprefix(each.value, "/"), "/", "-")}"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.5
  host           = "*"
  http_method    = "*"
  url_path       = "${each.value}*"
  service_name   = "*"
  service_type   = "*"
  resource_arn   = "*"

  tags = local.tags
}

# --- Trace insights group ---------------------------------------------------
resource "aws_xray_group" "errors" {
  group_name        = "${local.name}-errors"
  filter_expression = "error = true OR fault = true"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = local.tags
}