# ============================================================================
# modules/edge-security/shield-advanced — input variables
# NOTE: Shield Advanced is a $3,000/month subscription per AWS Organization.
# The subscription itself is enabled out-of-band / via the org master; this
# module manages PROTECTIONS on resources, not the subscription.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "protected_resources" {
  description = "Map of logical name => resource ARN to protect (CloudFront, ALB, EIP, Route53)."
  type        = map(string)
  default     = {}
}

variable "enable_drt_access" {
  description = "Grant the AWS Shield Response Team (SRT) access during attacks."
  type        = bool
  default     = false
}

variable "drt_role_arn" {
  description = "IAM role ARN for SRT access (required if enable_drt_access)."
  type        = string
  default     = null
}

variable "enable_proactive_engagement" {
  description = "Enable proactive engagement (SRT contacts you during events)."
  type        = bool
  default     = false
}

variable "emergency_contacts" {
  description = "Contacts for proactive engagement."
  type = list(object({
    email_address = string
    phone_number  = optional(string)
    contact_notes = optional(string)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}