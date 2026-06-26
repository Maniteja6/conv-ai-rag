# ============================================================================
# modules/observability/cloudwatch — shared / application log groups
# Service-specific groups are created by their own modules; these are the
# cross-cutting groups (application aggregate, audit, ingestion).
# ============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${local.name}/applications"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(local.tags, { LogClass = "application" })
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/${local.name}/audit"
  retention_in_days = 365 # audit logs retained longer for compliance
  kms_key_id        = var.kms_key_arn
  tags              = merge(local.tags, { LogClass = "audit" })
}

resource "aws_cloudwatch_log_group" "ingestion" {
  name              = "/aws/${local.name}/rag-ingestion"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(local.tags, { LogClass = "ingestion" })
}

# --- Metric filters: surface errors from app logs as metrics ---------------
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${local.name}-app-errors"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.level = \"ERROR\" }"

  metric_transformation {
    name          = "ApplicationErrors"
    namespace     = "${var.project}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "guardrail_blocks" {
  name           = "${local.name}-guardrail-blocks"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.event = \"guardrail_blocked\" }"

  metric_transformation {
    name          = "GuardrailBlocks"
    namespace     = "${var.project}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}