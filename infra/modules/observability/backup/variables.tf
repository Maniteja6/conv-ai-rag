# ============================================================================
# modules/observability/backup — input variables
# AWS Backup: centralized, policy-driven backups with cross-region copy for
# DR. Complements native PITR/snapshots on Aurora/DynamoDB.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key (backup domain) for the local vault."
  type        = string
}

variable "enable_cross_region_copy" {
  description = "Copy recovery points to a DR region."
  type        = bool
  default     = false
}

variable "dr_region" {
  type    = string
  default = "us-west-2"
}

variable "dr_vault_arn" {
  description = "Destination vault ARN in the DR region (created out-of-band or via provider alias)."
  type        = string
  default     = null
}

variable "backup_schedules" {
  description = "Backup rules: name => { schedule (cron), retention_days, cold_storage_after }."
  type = map(object({
    schedule           = string
    retention_days     = number
    cold_storage_after = optional(number)
    start_window_min   = optional(number, 60)
    completion_window_min = optional(number, 180)
  }))
  default = {
    daily = {
      schedule           = "cron(0 5 * * ? *)"
      retention_days     = 35
      cold_storage_after = null
    }
    weekly = {
      schedule           = "cron(0 6 ? * SUN *)"
      retention_days     = 90
      cold_storage_after = 30
    }
    monthly = {
      schedule           = "cron(0 7 1 * ? *)"
      retention_days     = 365
      cold_storage_after = 90
    }
  }
}

variable "backup_resource_arns" {
  description = "Explicit resource ARNs to back up (Aurora, DynamoDB, EFS, etc.)."
  type        = list(string)
  default     = []
}

variable "backup_selection_tag" {
  description = "Tag key/value selecting resources for backup."
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "Backup"
    value = "true"
  }
}

variable "backup_role_arn" {
  description = "IAM role for AWS Backup (created here if null)."
  type        = string
  default     = null
}

variable "enable_vault_lock" {
  description = "Enable Vault Lock (WORM) — IMMUTABLE, cannot be undone in compliance mode."
  type        = bool
  default     = false
}

variable "vault_lock_min_retention_days" {
  type    = number
  default = 7
}

variable "vault_lock_max_retention_days" {
  type    = number
  default = 365
}

variable "sns_topic_arn" {
  description = "SNS topic for backup job notifications."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}