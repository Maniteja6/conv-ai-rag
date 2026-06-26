# ============================================================================
# modules/security/kms — customer-managed keys + aliases
# ============================================================================

resource "aws_kms_key" "this" {
  for_each = local.key_domains

  description             = "${local.name}: ${each.value}"
  deletion_window_in_days = var.deletion_window_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = false
  policy                  = data.aws_iam_policy_document.key_policy[each.key].json

  tags = merge(local.tags, {
    Name   = "${local.name}-${each.key}-cmk"
    Domain = each.key
  })
}

resource "aws_kms_alias" "this" {
  for_each = local.key_domains

  name          = "alias/${local.name}-${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}