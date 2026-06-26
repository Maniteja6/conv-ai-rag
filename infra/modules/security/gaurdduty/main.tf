# ============================================================================
# modules/security/guardduty — detector + protection plans + finding routing
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "security/guardduty"
    ManagedBy   = "terraform"
  })
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-guardduty" })
}

# --- Route findings to EventBridge -> SNS ----------------------------------
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count       = var.sns_topic_arn != null ? 1 : 0
  name        = "${local.name}-guardduty-findings"
  description = "Capture GuardDuty findings (severity >= 4) and notify."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 4] }]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count     = var.sns_topic_arn != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "guardduty-to-sns"
  arn       = var.sns_topic_arn
}