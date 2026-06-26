# ============================================================================
# modules/networking/vpc — input variables
# ============================================================================

variable "project" {
  description = "Project slug used for naming and tagging."
  type        = string
  default     = "enterprise-ai-rag"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of AZs to span (must be exactly 3 for this architecture)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones are required."
  }
}

variable "eks_cluster_name" {
  description = "EKS cluster name, used for subnet discovery/ELB tags."
  type        = string
}

variable "single_nat_gateway" {
  description = "If true, route all private traffic through a single NAT GW (cost saving for non-prod)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention for VPC Flow Log group."
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting flow logs (optional; null = AWS-managed)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}