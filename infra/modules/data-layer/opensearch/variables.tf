# ============================================================================
# modules/data-layer/opensearch — input variables (RAG vector store)
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "engine_version" {
  description = "OpenSearch engine version (supports k-NN / vector search)."
  type        = string
  default     = "OpenSearch_2.13"
}

variable "vpc_subnet_ids" {
  description = "Private-data subnets for the domain ENIs (1 per AZ used)."
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "instance_type" {
  description = "Data node instance type."
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Number of data nodes (multiple of AZ count for balance)."
  type        = number
  default     = 3
}

variable "zone_awareness_enabled" {
  type    = bool
  default = true
}

variable "availability_zone_count" {
  type    = number
  default = 3
}

variable "dedicated_master_enabled" {
  type    = bool
  default = true
}

variable "dedicated_master_type" {
  type    = string
  default = "m6g.large.search"
}

variable "dedicated_master_count" {
  type    = number
  default = 3
}

variable "ebs_volume_size" {
  type    = number
  default = 100
}

variable "ebs_volume_type" {
  type    = string
  default = "gp3"
}

variable "master_user_secret_arn" {
  description = "Secret holding {username,password} for fine-grained access control."
  type        = string
  default     = null
}

variable "iam_access_role_arns" {
  description = "IAM role ARNs (e.g. retriever IRSA) allowed to call the domain."
  type        = list(string)
  default     = []
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}