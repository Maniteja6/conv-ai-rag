# ============================================================================
# modules/data-layer/aurora-postgresql — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_group_name" {
  description = "DB subnet group spanning the private-data subnets."
  type        = string
}

variable "security_group_id" {
  description = "Aurora security group (from networking/security-groups)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for storage + Performance Insights encryption."
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "Instance class for writer/readers (or serverless via min/max ACU)."
  type        = string
  default     = "db.r6g.large"
}

variable "use_serverless_v2" {
  description = "Use Aurora Serverless v2 scaling instead of provisioned instances."
  type        = bool
  default     = true
}

variable "serverless_min_acu" {
  type    = number
  default = 0.5
}

variable "serverless_max_acu" {
  type    = number
  default = 16
}

variable "reader_count" {
  description = "Number of reader instances (for read scaling / HA)."
  type        = number
  default     = 1
}

variable "database_name" {
  type    = string
  default = "ragplatform"
}

variable "master_username" {
  type    = string
  default = "dbadmin"
}

variable "master_password_secret_arn" {
  description = "Secrets Manager ARN holding the master password (json {value=...})."
  type        = string
  default     = null
}

variable "manage_master_password" {
  description = "Let RDS manage + rotate the master password in Secrets Manager."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  type    = number
  default = 14
}

variable "preferred_backup_window" {
  type    = string
  default = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  type    = string
  default = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "enable_rds_proxy" {
  description = "Provision an RDS Proxy for connection pooling (recommended for EKS)."
  type        = bool
  default     = true
}

variable "proxy_role_arn" {
  description = "IAM role ARN the proxy uses to fetch secrets (created here if null)."
  type        = string
  default     = null
}

variable "secrets_kms_key_arn" {
  description = "KMS key for the proxy auth secret."
  type        = string
  default     = null
}

variable "monitoring_role_arn" {
  description = "Enhanced monitoring role ARN (optional)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}