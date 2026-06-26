# ============================================================================
# modules/data-layer/opensearch — domain access policy
# Restricts ESHttp* to the specific IAM roles that need it (retriever,
# embedding, lambda ETL). With FGAC enabled, this is the coarse outer layer.
# ============================================================================

data "aws_iam_policy_document" "access" {
  statement {
    sid    = "AllowScopedRoles"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = length(var.iam_access_role_arns) > 0 ? var.iam_access_role_arns : ["arn:aws:iam::${var.account_id}:root"]
    }

    actions   = ["es:ESHttp*"]
    resources = ["arn:aws:es:${var.region}:${var.account_id}:domain/${local.domain_name}/*"]
  }
}

resource "aws_opensearch_domain_policy" "this" {
  domain_name     = aws_opensearch_domain.this.domain_name
  access_policies = data.aws_iam_policy_document.access.json
}