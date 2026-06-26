# ============================================================================
# modules/security/secrets-manager — automatic rotation
# Enabled only for secrets that support it and when a rotation Lambda is wired.
# ============================================================================

locals {
  # Secrets eligible for automatic rotation (DB-style credentials).
  rotatable_secrets = var.rotation_lambda_arn != null ? {
    for k, v in var.managed_secrets : k => v
    if contains(["aurora-master", "aurora-app", "redis-auth-token"], k)
  } : {}
}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = local.rotatable_secrets

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}