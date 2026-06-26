# ============================================================================
# modules/compute/eks-cluster — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  description = "EKS cluster name (must match the value used for subnet tags)."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control-plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  description = "Private subnets for the control-plane ENIs and worker nodes."
  type        = list(string)
}

variable "eks_nodes_security_group_id" {
  description = "Shared node security group (from networking/security-groups)."
  type        = string
}

variable "endpoint_public_access" {
  description = "Allow public access to the API server endpoint."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (if enabled)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for envelope-encrypting Kubernetes secrets (etcd)."
  type        = string
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for the control-plane CloudWatch log group."
  type        = string
  default     = null
}

variable "enabled_cluster_log_types" {
  description = "Control-plane log types to ship to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs granted cluster-admin via EKS access entries."
  type        = list(string)
  default     = []
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN for the EBS CSI driver (node volumes)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}