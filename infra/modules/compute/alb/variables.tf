# ============================================================================
# modules/compute/alb — input variables
# This ALB is the CloudFront origin AND the direct entry point for WebSocket
# (chat-gateway) traffic. Note: in EKS the AWS Load Balancer Controller
# typically provisions ALBs from Ingress objects. This module provisions a
# *standalone* ALB for cases where you want Terraform-managed listeners and
# the X-Origin-Verify enforcement. If you prefer controller-managed ALBs,
# use this only for the shared listener/WAF wiring.
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

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "certificate_arn" {
  description = "ACM cert ARN in the workload region for the HTTPS listener."
  type        = string
}

variable "additional_certificate_arns" {
  description = "Extra ACM certs (SNI) for additional hostnames."
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (optional)."
  type        = string
  default     = null
}

variable "origin_verify_secret" {
  description = "Expected value of X-Origin-Verify header from CloudFront. Requests without it (except WS) are rejected with 403."
  type        = string
  default     = null
  sensitive   = true
}

variable "idle_timeout" {
  description = "Idle timeout in seconds. Higher for streaming/SSE responses."
  type        = number
  default     = 120
}

variable "tags" {
  type    = map(string)
  default = {}
}