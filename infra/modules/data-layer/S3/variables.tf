# ============================================================================
# modules/data-layer/s3 — input variables (RAG document bucket + logs/assets)
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

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "force_destroy" {
  description = "Allow deleting non-empty buckets (true only for dev)."
  type        = bool
  default     = false
}

variable "enable_access_logs_bucket" {
  description = "Create a dedicated bucket for ALB/CloudFront/S3 access logs."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  type    = number
  default = 90
}

variable "transition_to_ia_days" {
  type    = number
  default = 30
}

variable "transition_to_glacier_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}