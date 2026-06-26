# ============================================================================
# modules/observability/backup — vaults
# ============================================================================

resource "aws_backup_vault" "this" {
  name        = "${local.name}-vault"
  kms_key_arn = var.kms_key_arn
  tags        = merge(local.tags, { Name = "${local.name}-vault" })
}

# --- Vault notifications ----------------------------------------------------
resource "aws_backup_vault_notifications" "this" {
  count               = var.sns_topic_arn != null ? 1 : 0
  backup_vault_name   = aws_backup_vault.this.name
  sns_topic_arn       = var.sns_topic_arn
  backup_vault_events = ["BACKUP_JOB_FAILED", "RESTORE_JOB_FAILED", "COPY_JOB_FAILED"]
}

# --- Vault Lock (WORM) — irreversible in compliance mode -------------------
resource "aws_backup_vault_lock_configuration" "this" {
  count               = var.enable_vault_lock ? 1 : 0
  backup_vault_name   = aws_backup_vault.this.name
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = 3 # grace period before lock becomes immutable
}