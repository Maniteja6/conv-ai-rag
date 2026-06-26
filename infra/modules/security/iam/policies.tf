# ============================================================================
# modules/security/iam — reusable customer-managed policies
# Each policy is least-privilege and scoped to specific resource ARNs.
# ============================================================================

# --- Bedrock invoke (model invocation only; no model management) -----------
data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    sid    = "InvokeBedrockModels"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:Retrieve",
      "bedrock:RetrieveAndGenerate",
      "bedrock:ApplyGuardrail",
    ]
    resources = [
      "arn:aws:bedrock:${var.region}::foundation-model/*",
      "arn:aws:bedrock:${var.region}:${var.account_id}:knowledge-base/*",
      "arn:aws:bedrock:${var.region}:${var.account_id}:guardrail/*",
    ]
  }
}

resource "aws_iam_policy" "bedrock_invoke" {
  name        = "${local.name}-bedrock-invoke"
  description = "Invoke Bedrock models, KBs, and guardrails."
  policy      = data.aws_iam_policy_document.bedrock_invoke.json
  tags        = local.tags
}

# --- S3 document bucket read/write -----------------------------------------
data "aws_iam_policy_document" "s3_documents" {
  count = var.document_bucket_arn != null ? 1 : 0

  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.document_bucket_arn]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectVersion",
    ]
    resources = ["${var.document_bucket_arn}/*"]
  }

  dynamic "statement" {
    for_each = lookup(var.kms_key_arns, "s3", null) != null ? [1] : []
    content {
      sid       = "S3KmsAccess"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.kms_key_arns["s3"]]
    }
  }
}

resource "aws_iam_policy" "s3_documents" {
  count       = var.document_bucket_arn != null ? 1 : 0
  name        = "${local.name}-s3-documents"
  description = "Read/write access to the RAG document bucket."
  policy      = data.aws_iam_policy_document.s3_documents[0].json
  tags        = local.tags
}

# --- OpenSearch read/write (HTTP verbs on the domain) ----------------------
data "aws_iam_policy_document" "opensearch_access" {
  count = var.opensearch_domain_arn != null ? 1 : 0

  statement {
    sid    = "OpenSearchHttp"
    effect = "Allow"
    actions = [
      "es:ESHttpGet", "es:ESHttpPost", "es:ESHttpPut",
      "es:ESHttpDelete", "es:ESHttpHead",
    ]
    resources = ["${var.opensearch_domain_arn}/*"]
  }
}

resource "aws_iam_policy" "opensearch_access" {
  count       = var.opensearch_domain_arn != null ? 1 : 0
  name        = "${local.name}-opensearch-access"
  description = "HTTP access to the OpenSearch vector index."
  policy      = data.aws_iam_policy_document.opensearch_access[0].json
  tags        = local.tags
}

# --- DynamoDB session/chat-history access ----------------------------------
data "aws_iam_policy_document" "dynamodb_access" {
  count = length(var.dynamodb_table_arns) > 0 ? 1 : 0

  statement {
    sid    = "DynamoCrud"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
      "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = concat(
      var.dynamodb_table_arns,
      [for arn in var.dynamodb_table_arns : "${arn}/index/*"]
    )
  }

  dynamic "statement" {
    for_each = lookup(var.kms_key_arns, "dynamodb", null) != null ? [1] : []
    content {
      sid       = "DynamoKms"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [var.kms_key_arns["dynamodb"]]
    }
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  count       = length(var.dynamodb_table_arns) > 0 ? 1 : 0
  name        = "${local.name}-dynamodb-access"
  description = "CRUD on session and chat-history tables."
  policy      = data.aws_iam_policy_document.dynamodb_access[0].json
  tags        = local.tags
}

# --- Secrets Manager read --------------------------------------------------
data "aws_iam_policy_document" "secrets_read" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  statement {
    sid       = "ReadSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secrets_arns
  }

  dynamic "statement" {
    for_each = lookup(var.kms_key_arns, "secrets", null) != null ? [1] : []
    content {
      sid       = "SecretsKms"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arns["secrets"]]
    }
  }
}

resource "aws_iam_policy" "secrets_read" {
  count       = length(var.secrets_arns) > 0 ? 1 : 0
  name        = "${local.name}-secrets-read"
  description = "Read application secrets from Secrets Manager."
  policy      = data.aws_iam_policy_document.secrets_read[0].json
  tags        = local.tags
}

# --- Observability: write logs, metrics, X-Ray traces ----------------------
data "aws_iam_policy_document" "observability" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/eks/${local.name}/*"]
  }

  statement {
    sid       = "CloudWatchMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["${var.project}/${var.environment}"]
    }
  }

  statement {
    sid    = "XRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments", "xray:PutTelemetryRecords",
      "xray:GetSamplingRules", "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "observability" {
  name        = "${local.name}-observability"
  description = "Emit logs, metrics, and X-Ray traces."
  policy      = data.aws_iam_policy_document.observability.json
  tags        = local.tags
}