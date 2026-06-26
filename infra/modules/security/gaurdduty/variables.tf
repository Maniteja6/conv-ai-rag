# ============================================================================
# modules/security/guardduty — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "enable_s3_protection" {
  description = "Enable GuardDuty S3 data event monitoring."
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Enable GuardDuty EKS audit log monitoring."
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Enable GuardDuty EBS malware scanning."
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "How often findings are exported (FIFTEEN_MINUTES | ONE_HOUR | SIX_HOURS)."
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for routing GuardDuty findings (optional)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}