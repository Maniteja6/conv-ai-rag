# ============================================================================
# modules/edge-security/waf — input variables
# Two WAF web ACLs are produced:
#   * CLOUDFRONT scope (must be created in us-east-1)
#   * REGIONAL scope   (for ALB / API Gateway in the workload region)
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "scope" {
  description = "WAF scope: CLOUDFRONT or REGIONAL."
  type        = string

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "rate_limit_per_5min" {
  description = "Max requests per 5-minute window per IP before blocking."
  type        = number
  default     = 2000
}

variable "rate_limit_api_per_5min" {
  description = "Stricter rate limit for /api/* paths."
  type        = number
  default     = 500
}

variable "blocked_countries" {
  description = "ISO 3166-1 alpha-2 country codes to geo-block (empty = none)."
  type        = list(string)
  default     = []
}

variable "allowed_countries" {
  description = "If non-empty, ONLY these countries are allowed (allowlist mode)."
  type        = list(string)
  default     = []
}

variable "ip_allowlist" {
  description = "CIDRs always allowed (e.g. corporate egress)."
  type        = list(string)
  default     = []
}

variable "ip_blocklist" {
  description = "CIDRs always blocked."
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "kms_key_arn" {
  description = "KMS key ARN for WAF log group encryption."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}