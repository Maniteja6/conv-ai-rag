# ============================================================================
# modules/security/iam — IRSA roles for workloads (per Kubernetes SA)
# Maps each microservice's service account to a least-privilege IAM role,
# attaching only the policies that service needs.
# ============================================================================

# Trust policy template for IRSA: federated to the cluster OIDC provider and
# locked to a specific namespace + service account subject.
data "aws_iam_policy_document" "irsa_trust" {
  for_each = local.irsa_enabled ? var.irsa_service_accounts : {}

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = local.irsa_enabled ? var.irsa_service_accounts : {}

  name               = "${local.name}-irsa-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[each.key].json

  tags = merge(local.tags, {
    Name           = "${local.name}-irsa-${each.key}"
    ServiceAccount = "${each.value.namespace}/${each.value.service_account}"
  })
}

# ----------------------------------------------------------------------------
# Per-service policy attachments. Defined as a flat list of (role_key, policy)
# pairs so attachments are explicit and auditable.
# ----------------------------------------------------------------------------
locals {
  # Which managed policies each service role receives.
  role_policy_map = local.irsa_enabled ? {
    # Agent orchestrator: full RAG surface
    "agent-orchestrator" = compact([
      aws_iam_policy.bedrock_invoke.arn,
      aws_iam_policy.observability.arn,
      try(aws_iam_policy.s3_documents[0].arn, ""),
      try(aws_iam_policy.opensearch_access[0].arn, ""),
      try(aws_iam_policy.secrets_read[0].arn, ""),
    ])
    # Retriever: OpenSearch + S3 + Bedrock (rerank/embeddings)
    "retriever-service" = compact([
      aws_iam_policy.bedrock_invoke.arn,
      aws_iam_policy.observability.arn,
      try(aws_iam_policy.opensearch_access[0].arn, ""),
      try(aws_iam_policy.s3_documents[0].arn, ""),
    ])
    # Embedding: Bedrock Titan only
    "embedding-service" = compact([
      aws_iam_policy.bedrock_invoke.arn,
      aws_iam_policy.observability.arn,
    ])
    # Guardrails: Bedrock ApplyGuardrail
    "guardrails-service" = compact([
      aws_iam_policy.bedrock_invoke.arn,
      aws_iam_policy.observability.arn,
    ])
    # Session: DynamoDB + secrets (Redis auth)
    "session-service" = compact([
      aws_iam_policy.observability.arn,
      try(aws_iam_policy.dynamodb_access[0].arn, ""),
      try(aws_iam_policy.secrets_read[0].arn, ""),
    ])
    # Text-to-SQL: secrets (DB creds) + observability
    "text-to-sql-service" = compact([
      aws_iam_policy.observability.arn,
      try(aws_iam_policy.secrets_read[0].arn, ""),
    ])
    # API + chat gateway + query-router: observability + secrets
    "api-service"   = compact([aws_iam_policy.observability.arn, try(aws_iam_policy.secrets_read[0].arn, "")])
    "chat-gateway"  = compact([aws_iam_policy.observability.arn, try(aws_iam_policy.secrets_read[0].arn, "")])
    "query-router"  = compact([aws_iam_policy.observability.arn, aws_iam_policy.bedrock_invoke.arn])
  } : {}

  # Flatten to (role_key, policy_arn) attachment pairs.
  role_attachments = merge([
    for role_key, arns in local.role_policy_map : {
      for arn in arns : "${role_key}::${arn}" => {
        role_key   = role_key
        policy_arn = arn
      }
    }
  ]...)
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = {
    for k, v in local.role_attachments : k => v
    if contains(keys(var.irsa_service_accounts), v.role_key)
  }

  role       = aws_iam_role.irsa[each.value.role_key].name
  policy_arn = each.value.policy_arn
}