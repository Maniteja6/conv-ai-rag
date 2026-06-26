# ============================================================================
# modules/compute/eks-node-groups — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "eks_nodes_security_group_id" {
  type = string
}

variable "cluster_security_group_id" {
  description = "EKS-managed cluster SG (nodes must allow it)."
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN for node root/data EBS volumes."
  type        = string
  default     = null
}

# Baseline managed node group (runs system/critical addons reliably).
variable "system_node_group" {
  description = "Config for the always-on system managed node group."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    capacity_type  = string # ON_DEMAND | SPOT
  })
  default = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    disk_size      = 50
    capacity_type  = "ON_DEMAND"
  }
}

variable "enable_karpenter" {
  description = "Provision Karpenter IAM/instance profile for dynamic node scaling."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  type    = string
  default = null
}

variable "oidc_provider_url" {
  type    = string
  default = null
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