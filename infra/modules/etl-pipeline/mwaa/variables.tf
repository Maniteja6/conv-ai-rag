# ============================================================================
# modules/etl-pipeline/mwaa — input variables
# Managed Airflow orchestrates batch ingestion (document_ingestion_dag),
# scheduled embedding refresh, and index maintenance.
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

variable "mwaa_role_arn" {
  description = "MWAA execution role ARN (from modules/security/iam mwaa_role_arn)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Exactly 2 private subnets for MWAA (service requirement)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "MWAA requires exactly 2 private subnets."
  }
}

variable "source_bucket_arn" {
  description = "S3 bucket ARN storing DAGs / requirements / plugins."
  type        = string
}

variable "source_bucket_id" {
  type = string
}

variable "dags_s3_path" {
  type    = string
  default = "dags/"
}

variable "requirements_s3_path" {
  type    = string
  default = "requirements.txt"
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "airflow_version" {
  type    = string
  default = "2.10.1"
}

variable "environment_class" {
  description = "mw1.small | mw1.medium | mw1.large"
  type        = string
  default     = "mw1.small"
}

variable "min_workers" {
  type    = number
  default = 1
}

variable "max_workers" {
  type    = number
  default = 5
}

variable "webserver_access_mode" {
  description = "PRIVATE_ONLY (VPC) or PUBLIC_ONLY."
  type        = string
  default     = "PRIVATE_ONLY"
}

variable "source_security_group_ids" {
  description = "Additional SGs allowed to reach the MWAA environment."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}