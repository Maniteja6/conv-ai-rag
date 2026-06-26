# ============================================================================
# modules/ai-ml/bedrock — model inventory + invocation logging
# ----------------------------------------------------------------------------
# NOTE: "Model access" (the entitlement to invoke a given foundation model) is
# granted at the account level via the Bedrock console / Marketplace, or with
# the `bedrock:PutUseCaseForModelAccess` + entitlement APIs — it is NOT a
# first-class Terraform resource. This file therefore:
#   1. Asserts the configured models are available (data sources).
#   2. Configures account-wide invocation logging (the auditable artifact).
# The IAM permission to call InvokeModel lives in modules/security/iam
# (bedrock_invoke policy) and is attached to the relevant IRSA roles.
# ============================================================================

# --- Verify the configured models exist / are reachable --------------------
data "aws_bedrock_foundation_model" "text" {
  model_id = var.text_model_id
}

data "aws_bedrock_foundation_model" "embedding" {
  model_id = var.embedding_model_id
}

# --- Invocation logging -----------------------------------------------------
resource "aws_cloudwatch_log_group" "bedrock_invocations" {
  count             = var.enable_invocation_logging ? 1 : 0
  name              = "/aws/bedrock/${local.name}/invocations"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn
  tags              = local.tags
}

# Role allowing Bedrock to write invocation logs.
data "aws_iam_policy_document" "bedrock_logging_assume" {
  count = var.enable_invocation_logging ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_iam_role" "bedrock_logging" {
  count              = var.enable_invocation_logging ? 1 : 0
  name               = "${local.name}-bedrock-logging"
  assume_role_policy = data.aws_iam_policy_document.bedrock_logging_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "bedrock_logging" {
  count = var.enable_invocation_logging ? 1 : 0

  statement {
    sid       = "WriteCloudWatch"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.bedrock_invocations[0].arn}:*"]
  }

  dynamic "statement" {
    for_each = var.invocation_log_bucket != null ? [1] : []
    content {
      sid       = "WriteS3"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["arn:aws:s3:::${var.invocation_log_bucket}/bedrock/*"]
    }
  }
}

resource "aws_iam_role_policy" "bedrock_logging" {
  count  = var.enable_invocation_logging ? 1 : 0
  name   = "${local.name}-bedrock-logging"
  role   = aws_iam_role.bedrock_logging[0].id
  policy = data.aws_iam_policy_document.bedrock_logging[0].json
}

# Account-level model invocation logging configuration.
resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  count = var.enable_invocation_logging ? 1 : 0

  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = false
    text_data_delivery_enabled      = true

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_invocations[0].name
      role_arn       = aws_iam_role.bedrock_logging[0].arn

      dynamic "large_data_delivery_s3_config" {
        for_each = var.invocation_log_bucket != null ? [1] : []
        content {
          bucket_name = var.invocation_log_bucket
          key_prefix  = "bedrock/large-payloads/"
        }
      }
    }

    dynamic "s3_config" {
      for_each = var.invocation_log_bucket != null ? [1] : []
      content {
        bucket_name = var.invocation_log_bucket
        key_prefix  = "bedrock/invocations/"
      }
    }
  }

  depends_on = [aws_iam_role_policy.bedrock_logging]
}