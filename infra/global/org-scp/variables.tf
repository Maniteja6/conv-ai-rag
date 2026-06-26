# ============================================================================
# global/org-scp — SCP document
# ============================================================================

variable "aws_region" { type = string, default = "us-east-1" }
variable "target_ou_ids" {
  description = "Organizational Unit IDs to attach the SCP to."
  type        = list(string)
  default     = []
}
variable "allowed_regions" {
  description = "Regions member accounts may operate in."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

data "aws_iam_policy_document" "scp" {
  # --- Region lockdown (except global services) ---
  statement {
    sid       = "DenyOutsideAllowedRegions"
    effect    = "Deny"
    not_actions = [
      "iam:*", "organizations:*", "route53:*", "cloudfront:*",
      "waf:*", "wafv2:*", "shield:*", "sts:*", "support:*",
      "budgets:*", "ce:*", "globalaccelerator:*",
    ]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }

  # --- Prevent disabling security services ---
  statement {
    sid    = "ProtectSecurityServices"
    effect = "Deny"
    actions = [
      "guardduty:DeleteDetector", "securityhub:DisableSecurityHub",
      "cloudtrail:StopLogging", "cloudtrail:DeleteTrail",
      "config:DeleteConfigurationRecorder", "config:StopConfigurationRecorder",
    ]
    resources = ["*"]
  }

  # --- Require encryption: deny unencrypted EBS/RDS/S3 ---
  statement {
    sid       = "DenyUnencryptedS3Uploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
  }

  # --- Deny root user actions ---
  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}