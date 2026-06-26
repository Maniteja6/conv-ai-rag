# ============================================================================
# modules/data-layer/elasticache-redis — input variables
# Backs session-service (low-latency session store) + general caching.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "subnet_group_name" {
  description = "ElastiCache subnet group (private-data subnets)."
  type        = string
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "7.1"
}

variable "node_type" {
  type    = string
  default = "cache.r6g.large"
}

variable "num_node_groups" {
  description = "Number of shards (cluster mode)."
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Read replicas per shard (HA)."
  type        = number
  default     = 1
}

variable "multi_az_enabled" {
  type    = bool
  default = true
}

variable "automatic_failover_enabled" {
  type    = bool
  default = true
}

variable "auth_token_secret_arn" {
  description = "Secret holding the Redis AUTH token (json {value=...})."
  type        = string
  default     = null
}

variable "snapshot_retention_days" {
  type    = number
  default = 7
}

variable "sns_topic_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}