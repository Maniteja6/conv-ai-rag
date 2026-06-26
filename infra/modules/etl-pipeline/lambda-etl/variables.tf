# ============================================================================
# modules/etl-pipeline/lambda-etl — input variables
# Four functions chained: document-parser -> chunk-generator ->
# embedding-generator -> opensearch-index-loader.
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

# --- Networking (Lambdas run in-VPC to reach OpenSearch + endpoints) -------
variable "vpc_subnet_ids" {
  description = "Private-app subnets for Lambda ENIs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups allowing egress to OpenSearch + VPC endpoints."
  type        = list(string)
}

# --- IAM --------------------------------------------------------------------
variable "execution_role_arn" {
  description = "Lambda execution role ARN (from modules/security/iam lambda_etl_role_arn)."
  type        = string
}

# --- Source / sink ----------------------------------------------------------
variable "document_bucket_id" {
  description = "S3 bucket holding source documents (triggers ingestion)."
  type        = string
}

variable "document_bucket_arn" {
  type = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch HTTPS endpoint for the loader."
  type        = string
}

variable "opensearch_index" {
  type    = string
  default = "rag-vector-index"
}

variable "embedding_model_id" {
  type    = string
  default = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimensions" {
  type    = number
  default = 1024
}

# --- Packaging --------------------------------------------------------------
variable "source_dir" {
  description = "Path to data-pipeline/lambda-functions (for archive packaging)."
  type        = string
  default     = "../../../data-pipeline/lambda-functions"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "architecture" {
  type    = string
  default = "arm64" # Graviton: cheaper + faster for these workloads
}

variable "kms_key_arn" {
  description = "KMS key for Lambda env var encryption."
  type        = string
  default     = null
}

# --- Per-function sizing ----------------------------------------------------
variable "function_config" {
  description = "Per-function memory/timeout overrides."
  type = map(object({
    memory_mb   = number
    timeout_sec = number
  }))
  default = {
    document-parser         = { memory_mb = 2048, timeout_sec = 300 }
    chunk-generator         = { memory_mb = 1024, timeout_sec = 180 }
    embedding-generator     = { memory_mb = 1024, timeout_sec = 600 }
    opensearch-index-loader = { memory_mb = 1024, timeout_sec = 300 }
  }
}

variable "dlq_arn" {
  description = "SQS DLQ ARN for failed async invocations (optional)."
  type        = string
  default     = null
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}