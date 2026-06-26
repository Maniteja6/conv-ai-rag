# ============================================================================
# modules/security/kms — per-key IAM policy documents
# Grants:
#   * Root account full administration (account-recovery safety)
#   * Optional admin roles full key management
#   * The relevant AWS service principal encrypt/decrypt via grants
# ============================================================================

data "aws_iam_policy_document" "key_policy" {
  for_each = local.key_domains

  # --- Root account administration ---
  statement {
    sid       = "EnableRootAccount"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  # --- Dedicated key administrators ---
  dynamic "statement" {
    for_each = length(var.admin_role_arns) > 0 ? [1] : []
    content {
      sid    = "KeyAdministration"
      effect = "Allow"
      actions = [
        "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*",
        "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*",
        "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource",
        "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = var.admin_role_arns
      }
    }
  }

  # --- Allow the owning AWS service to use the key via the account ---
  statement {
    sid    = "AllowServiceViaAccount"
    effect = "Allow"
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.via_service[each.key]]
    }
  }

  # --- CloudWatch Logs needs explicit service-principal access ---
  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []
    content {
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
      actions = [
        "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:Describe*",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["logs.${var.region}.amazonaws.com"]
      }
      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:*"]
      }
    }
  }

  # --- AWS Backup service principal ---
  dynamic "statement" {
    for_each = each.key == "backup" ? [1] : []
    content {
      sid    = "AllowAWSBackup"
      effect = "Allow"
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["backup.amazonaws.com"]
      }
    }
  }
}

locals {
  # ViaService condition value per domain — restricts key usage to the
  # intended AWS service even when delegated through the account root.
  via_service = {
    rds        = "rds.${var.region}.amazonaws.com"
    opensearch = "es.${var.region}.amazonaws.com"
    redis      = "elasticache.${var.region}.amazonaws.com"
    dynamodb   = "dynamodb.${var.region}.amazonaws.com"
    s3         = "s3.${var.region}.amazonaws.com"
    secrets    = "secretsmanager.${var.region}.amazonaws.com"
    logs       = "logs.${var.region}.amazonaws.com"
    ebs        = "ec2.${var.region}.amazonaws.com"
    sns        = "sns.${var.region}.amazonaws.com"
    backup     = "backup.${var.region}.amazonaws.com"
  }
}