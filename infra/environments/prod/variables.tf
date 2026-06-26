# ============================================================================
# environments/prod — variable declarations
# ============================================================================

variable "project" { type = string, default = "enterprise-ai-rag" }
variable "aws_region" { type = string }
variable "availability_zones" { type = list(string) }
variable "cost_center" { type = string, default = "ai-platform" }

# Networking
variable "vpc_cidr" { type = string }
variable "domain_name" { type = string }
variable "create_public_zone" { type = bool, default = true }

# KMS / IAM
variable "kms_admin_role_arns" { type = list(string), default = [] }
variable "cluster_admin_principal_arns" { type = list(string), default = [] }

# EKS
variable "cluster_name" { type = string }
variable "kubernetes_version" { type = string, default = "1.30" }
variable "eks_endpoint_public_access" { type = bool, default = false }
variable "eks_public_access_cidrs" { type = list(string), default = [] }
variable "system_node_group" {
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    capacity_type  = string
  })
}

# Data layer
variable "aurora_serverless" { type = bool, default = true }
variable "aurora_min_acu" { type = number, default = 2 }
variable "aurora_max_acu" { type = number, default = 32 }
variable "aurora_reader_count" { type = number, default = 2 }
variable "opensearch_instance_type" { type = string, default = "r6g.large.search" }
variable "opensearch_instance_count" { type = number, default = 3 }
variable "create_opensearch_slr" { type = bool, default = false }
variable "redis_node_type" { type = string, default = "cache.r6g.large" }
variable "redis_num_shards" { type = number, default = 1 }
variable "redis_replicas_per_shard" { type = number, default = 2 }
variable "enable_dynamodb_global_tables" { type = bool, default = false }
variable "dynamodb_replica_regions" { type = list(string), default = [] }

# Edge / ACM / secrets
variable "acm_certificate_arn_regional" { type = string }
variable "acm_certificate_arn_cloudfront" { type = string }
variable "origin_verify_secret" { type = string, sensitive = true }
variable "cloudfront_aliases" { type = list(string), default = [] }
variable "cloudfront_price_class" { type = string, default = "PriceClass_100" }
variable "waf_rate_limit" { type = number, default = 2000 }
variable "waf_blocked_countries" { type = list(string), default = [] }
variable "enable_shield_advanced" { type = bool, default = false }
variable "shield_emergency_contacts" {
  type = list(object({
    email_address = string
    phone_number  = optional(string)
    contact_notes = optional(string)
  }))
  default = []
}

# AI/ML
variable "bedrock_text_model_id" { type = string, default = "anthropic.claude-sonnet-4-20250514-v1:0" }
variable "bedrock_embedding_model_id" { type = string, default = "amazon.titan-embed-text-v2:0" }
variable "embedding_dimensions" { type = number, default = 1024 }
variable "enable_bedrock_knowledge_base" { type = bool, default = false }
variable "enable_sagemaker_reranker" { type = bool, default = false }
variable "sagemaker_model_image" { type = string, default = null }

# ETL
variable "mwaa_environment_class" { type = string, default = "mw1.medium" }
variable "mwaa_max_workers" { type = number, default = 10 }

# Observability / DR / compliance
variable "log_retention_days" { type = number, default = 90 }
variable "xray_sampling_rate" { type = number, default = 0.1 }
variable "enable_backup_cross_region" { type = bool, default = true }
variable "dr_region" { type = string, default = "us-west-2" }
variable "enable_backup_vault_lock" { type = bool, default = false }
variable "enable_pci_compliance" { type = bool, default = false }
variable "alert_email_addresses" { type = list(string), default = [] }
variable "pagerduty_endpoint" { type = string, default = null }