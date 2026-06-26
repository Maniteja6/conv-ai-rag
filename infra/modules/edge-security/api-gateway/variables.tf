# ============================================================================
# modules/edge-security/api-gateway — input variables
# Provides a managed REST API front (throttling, usage plans, JWT/Cognito
# authorization) for partner/programmatic access, complementing the ALB path.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "vpc_link_subnet_ids" {
  description = "Private subnets for the VPC Link to reach the internal NLB/ALB."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "Security groups for the VPC Link ENIs."
  type        = list(string)
  default     = []
}

variable "nlb_listener_arn" {
  description = "Internal NLB listener ARN that fronts the EKS services (HTTP_PROXY integration target)."
  type        = string
  default     = null
}

variable "cognito_user_pool_arn" {
  description = "Cognito user pool ARN for the JWT authorizer."
  type        = string
  default     = null
}

variable "jwt_issuer" {
  description = "OIDC issuer URL (if using a JWT authorizer instead of Cognito)."
  type        = string
  default     = null
}

variable "jwt_audiences" {
  description = "Accepted JWT audiences."
  type        = list(string)
  default     = []
}

variable "web_acl_arn" {
  description = "REGIONAL WAF web ACL ARN to associate with the API stage."
  type        = string
  default     = null
}

variable "throttle_rate_limit" {
  description = "Default steady-state requests/sec across the stage."
  type        = number
  default     = 1000
}

variable "throttle_burst_limit" {
  description = "Default burst capacity."
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}