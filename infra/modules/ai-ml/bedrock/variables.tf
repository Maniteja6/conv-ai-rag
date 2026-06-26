# ============================================================================
# modules/ai-ml/bedrock — input variables
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

# --- Models -----------------------------------------------------------------
variable "text_model_id" {
  description = "Primary text/chat foundation model ID (matches diagram: Claude 4)."
  type        = string
  default     = "anthropic.claude-sonnet-4-20250514-v1:0"
}

variable "embedding_model_id" {
  description = "Embedding model for the knowledge base (matches diagram: Titan Embeddings)."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimensions" {
  description = "Vector dimension produced by the embedding model (Titan v2 = 1024)."
  type        = number
  default     = 1024
}

# --- Invocation logging -----------------------------------------------------
variable "enable_invocation_logging" {
  description = "Log all Bedrock model invocations to CloudWatch + S3 (audit/compliance)."
  type        = bool
  default     = true
}

variable "invocation_log_bucket" {
  description = "S3 bucket for large invocation payloads (>= request/response bodies)."
  type        = string
  default     = null
}

variable "logs_kms_key_arn" {
  type    = string
  default = null
}

variable "log_retention_days" {
  type    = number
  default = 90
}

# --- Guardrails -------------------------------------------------------------
variable "enable_guardrails" {
  type    = bool
  default = true
}

variable "guardrail_blocked_input_message" {
  type    = string
  default = "I'm unable to process that request as it conflicts with usage policies."
}

variable "guardrail_blocked_output_message" {
  type    = string
  default = "I'm unable to provide that response."
}

variable "pii_entities_to_anonymize" {
  description = "PII entity types to mask in inputs/outputs."
  type        = list(string)
  default = [
    "EMAIL", "PHONE", "NAME", "ADDRESS", "CREDIT_DEBIT_CARD_NUMBER",
    "US_SOCIAL_SECURITY_NUMBER", "PASSWORD", "AWS_ACCESS_KEY", "AWS_SECRET_KEY",
  ]
}

variable "denied_topics" {
  description = "Custom denied topics: name => definition."
  type        = map(string)
  default = {
    LegalAdvice      = "Providing specific legal advice or interpretation of laws for a user's situation."
    MedicalDiagnosis = "Diagnosing medical conditions or recommending specific treatments."
    FinancialAdvice  = "Providing personalized investment or financial planning advice."
  }
}

variable "word_filters" {
  description = "Custom words/phrases to block."
  type        = list(string)
  default     = []
}

# --- Knowledge base ---------------------------------------------------------
variable "enable_knowledge_base" {
  type    = bool
  default = true
}

variable "document_bucket_arn" {
  description = "S3 bucket ARN containing source documents for ingestion."
  type        = string
  default     = null
}

variable "opensearch_collection_arn" {
  description = "OpenSearch Serverless collection ARN OR provisioned domain ARN for the vector store."
  type        = string
  default     = null
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint hosting the vector index."
  type        = string
  default     = null
}

variable "vector_index_name" {
  type    = string
  default = "rag-vector-index"
}

variable "kb_role_arn" {
  description = "IAM role ARN the Knowledge Base assumes (created here if null)."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key for KB transient data encryption."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}