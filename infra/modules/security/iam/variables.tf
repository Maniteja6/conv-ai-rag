# ============================================================================
# modules/security/iam — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN (for IRSA trust policies)."
  type        = string
  default     = null
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL without https:// (e.g. oidc.eks.us-east-1.amazonaws.com/id/XXXX)."
  type        = string
  default     = null
}

variable "kms_key_arns" {
  description = "Map of domain => KMS key ARN (from the kms module) for scoping policies."
  type        = map(string)
  default     = {}
}

variable "document_bucket_arn" {
  description = "S3 document bucket ARN (for RAG service access). Optional at first apply."
  type        = string
  default     = null
}

variable "opensearch_domain_arn" {
  description = "OpenSearch domain ARN (for retriever/embedding access)."
  type        = string
  default     = null
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs (sessions, chat-history)."
  type        = list(string)
  default     = []
}

variable "secrets_arns" {
  description = "Secrets Manager secret ARNs the services may read."
  type        = list(string)
  default     = []
}

# Map of Kubernetes service account (namespace/name) => role purpose.
variable "irsa_service_accounts" {
  description = "IRSA bindings: logical name => { namespace, service_account }."
  type = map(object({
    namespace       = string
    service_account = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}