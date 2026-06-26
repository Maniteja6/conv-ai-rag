# ============================================================================
# modules/security/kms — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "account_id" {
  description = "AWS account ID (for key policy principals)."
  type        = string
}

variable "region" {
  type = string
}

variable "deletion_window_days" {
  description = "Waiting period before a scheduled key deletion completes."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_days >= 7 && var.deletion_window_days <= 30
    error_message = "deletion_window_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "admin_role_arns" {
  description = "IAM role ARNs allowed to administer the KMS keys."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}