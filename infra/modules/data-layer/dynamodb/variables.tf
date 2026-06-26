# ============================================================================
# modules/data-layer/dynamodb — input variables
# Tables: sessions (TTL'd), chat-history (per-conversation message log).
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "point_in_time_recovery" {
  type    = bool
  default = true
}

variable "enable_global_tables" {
  description = "Replicate tables to other regions (multi-region DR). Matches the diagram's 'Regional' label when false."
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "Regions to replicate to when enable_global_tables = true."
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}