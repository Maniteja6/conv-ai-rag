# ============================================================================
# modules/observability/cloudwatch — SNS alerting hub
# This topic is the single notification path for the whole platform:
# alarms, GuardDuty findings, RDS events, Redis events, Karpenter, backups.
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "observability/cloudwatch"
    ManagedBy   = "terraform"
  })
}

# --- Alerts topic -----------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name              = "${local.name}-alerts"
  kms_master_key_id = var.kms_key_arn
  tags              = merge(local.tags, { Name = "${local.name}-alerts" })
}

# Allow AWS services (CloudWatch, EventBridge, RDS) to publish.
data "aws_iam_policy_document" "alerts_topic" {
  statement {
    sid    = "AllowServicePublish"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "events.amazonaws.com",
        "rds.amazonaws.com",
        "elasticache.amazonaws.com",
        "backup.amazonaws.com",
      ]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_topic.json
}

# --- Subscriptions ----------------------------------------------------------
resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.alert_email_addresses)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "pagerduty" {
  count                  = var.pagerduty_endpoint != null ? 1 : 0
  topic_arn              = aws_sns_topic.alerts.arn
  protocol               = "https"
  endpoint               = var.pagerduty_endpoint
  endpoint_auto_confirms = true
}

# --- Critical topic (paging only) ------------------------------------------
resource "aws_sns_topic" "critical" {
  name              = "${local.name}-critical"
  kms_master_key_id = var.kms_key_arn
  tags              = merge(local.tags, { Name = "${local.name}-critical" })
}

resource "aws_sns_topic_subscription" "critical_pagerduty" {
  count                  = var.pagerduty_endpoint != null ? 1 : 0
  topic_arn              = aws_sns_topic.critical.arn
  protocol               = "https"
  endpoint               = var.pagerduty_endpoint
  endpoint_auto_confirms = true
}