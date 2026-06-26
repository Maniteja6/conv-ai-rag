# ============================================================================
# modules/observability/backup — plan, rules, resource selection
# ============================================================================

resource "aws_backup_plan" "this" {
  name = "${local.name}-plan"

  dynamic "rule" {
    for_each = var.backup_schedules
    content {
      rule_name         = rule.key
      target_vault_name = aws_backup_vault.this.name
      schedule          = rule.value.schedule
      start_window      = rule.value.start_window_min
      completion_window = rule.value.completion_window_min

      lifecycle {
        delete_after       = rule.value.retention_days
        cold_storage_after = rule.value.cold_storage_after
      }

      # Cross-region copy for DR.
      dynamic "copy_action" {
        for_each = var.enable_cross_region_copy && var.dr_vault_arn != null ? [1] : []
        content {
          destination_vault_arn = var.dr_vault_arn
          lifecycle {
            delete_after = rule.value.retention_days
          }
        }
      }

      recovery_point_tags = merge(local.tags, { BackupRule = rule.key })
    }
  }

  tags = local.tags
}

# --- Selection by tag -------------------------------------------------------
resource "aws_backup_selection" "by_tag" {
  name         = "${local.name}-by-tag"
  iam_role_arn = local.role_arn
  plan_id      = aws_backup_plan.this.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_selection_tag.key
    value = var.backup_selection_tag.value
  }
}

# --- Selection by explicit ARN ---------------------------------------------
resource "aws_backup_selection" "by_arn" {
  count        = length(var.backup_resource_arns) > 0 ? 1 : 0
  name         = "${local.name}-by-arn"
  iam_role_arn = local.role_arn
  plan_id      = aws_backup_plan.this.id
  resources    = var.backup_resource_arns
}