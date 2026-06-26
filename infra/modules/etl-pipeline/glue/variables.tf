# ============================================================================
# modules/etl-pipeline/glue — input variables
# Glue Data Catalog + crawlers index document metadata and any structured
# data the text-to-sql-service queries. Also catalogs the chunk/embedding
# manifests in S3 for lineage + analytics.
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

variable "glue_role_arn" {
  description = "Glue service role ARN (from modules/security/iam glue_role_arn)."
  type        = string
}

variable "document_bucket_id" {
  type = string
}

variable "glue_scripts_bucket" {
  description = "S3 bucket for Glue job scripts."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "crawler_schedule" {
  description = "Cron schedule for the metadata crawler."
  type        = string
  default     = "cron(0 */6 * * ? *)" # every 6 hours
}

variable "tags" {
  type    = map(string)
  default = {}
}