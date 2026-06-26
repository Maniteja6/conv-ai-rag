# ============================================================================
# modules/security/secrets-manager — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting secrets (from kms module 'secrets' domain)."
  type        = string
}

variable "recovery_window_days" {
  description = "Days before a deleted secret is permanently removed (0 = force delete)."
  type        = number
  default     = 7
}

variable "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda (optional; enables automatic rotation)."
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Automatic rotation interval in days."
  type        = number
  default     = 30
}

# Application secrets to provision. Values are typically injected out-of-band
# (CI, manual, or generated) — here we create the containers + access wiring.
variable "managed_secrets" {
  description = "Logical name => description for secrets to create."
  type        = map(string)
  default = {
    aurora-master       = "Aurora PostgreSQL master credentials"
    aurora-app          = "Aurora application user credentials"
    redis-auth-token    = "ElastiCache Redis AUTH token"
    opensearch-master   = "OpenSearch master user credentials"
    jwt-signing-key     = "JWT signing secret for API auth"
    bedrock-api-config  = "Bedrock client configuration"
  }
}

variable "generate_random_secrets" {
  description = "Whether to seed secrets with a generated random value on create."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}