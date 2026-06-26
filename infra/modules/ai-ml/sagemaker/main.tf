# ============================================================================
# modules/ai-ml/sagemaker — execution role + model
# ============================================================================

locals {
  name    = "${var.project}-${var.environment}"
  enabled = var.enable_endpoint

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "ai-ml/sagemaker"
    ManagedBy   = "terraform"
  })
}

# --- Execution role ---------------------------------------------------------
data "aws_iam_policy_document" "sm_assume" {
  count = local.enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  count              = local.enabled ? 1 : 0
  name               = "${local.name}-sagemaker-exec"
  assume_role_policy = data.aws_iam_policy_document.sm_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "sm_exec" {
  count = local.enabled ? 1 : 0

  statement {
    sid    = "EcrPull"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability", "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.model_artifacts_bucket_arn != null ? [1] : []
    content {
      sid       = "ReadModelArtifacts"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = [var.model_artifacts_bucket_arn, "${var.model_artifacts_bucket_arn}/*"]
    }
  }

  statement {
    sid    = "Observability"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData", "logs:CreateLogGroup", "logs:CreateLogStream",
      "logs:PutLogEvents", "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      sid       = "KmsUse"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "sm_exec" {
  count  = local.enabled ? 1 : 0
  name   = "${local.name}-sagemaker-exec"
  role   = aws_iam_role.execution[0].id
  policy = data.aws_iam_policy_document.sm_exec[0].json
}

# --- Model ------------------------------------------------------------------
resource "aws_sagemaker_model" "this" {
  count            = local.enabled ? 1 : 0
  name             = "${local.name}-model"
  execution_role_arn = aws_iam_role.execution[0].arn

  primary_container {
    image          = var.model_image
    model_data_url = var.model_data_url
    environment    = var.model_environment
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnets            = var.vpc_subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-model" })
}