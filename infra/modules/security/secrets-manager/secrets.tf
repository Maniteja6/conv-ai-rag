# ============================================================================
# modules/security/secrets-manager — secret resources
# ============================================================================

resource "aws_secretsmanager_secret" "this" {
  for_each = var.managed_secrets

  name                    = "${local.name}/${each.key}"
  description             = each.value
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_days

  tags = merge(local.tags, {
    Name   = "${local.name}-${each.key}"
    Secret = each.key
  })
}

# Generate strong random values to seed secrets on first create. Real values
# (e.g. RDS-managed master passwords) overwrite these out-of-band; the
# lifecycle ignore prevents Terraform from clobbering rotated values.
resource "random_password" "seed" {
  for_each = var.generate_random_secrets ? var.managed_secrets : {}

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "seed" {
  for_each = var.generate_random_secrets ? var.managed_secrets : {}

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = jsonencode({ value = random_password.seed[each.key].result })

  lifecycle {
    ignore_changes = [secret_string]
  }
}