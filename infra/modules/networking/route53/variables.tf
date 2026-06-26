# ============================================================================
# modules/networking/route53 — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "domain_name" {
  description = "Root domain for the platform (e.g. ai-platform.example.com)."
  type        = string
}

variable "create_public_zone" {
  description = "Create a public hosted zone (false if managed elsewhere)."
  type        = bool
  default     = true
}

variable "create_private_zone" {
  description = "Create a private hosted zone for internal service discovery."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to associate with the private hosted zone."
  type        = string
  default     = null
}

variable "alb_dns_name" {
  description = "Public ALB DNS name (alias target)."
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "Public ALB hosted zone ID (alias target)."
  type        = string
  default     = null
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain (alias target, takes priority over ALB if set)."
  type        = string
  default     = null
}

variable "cloudfront_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2)."
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "health_check_path" {
  description = "Path for the ALB origin health check."
  type        = string
  default     = "/health"
}

variable "health_check_fqdn" {
  description = "FQDN to health check (e.g. origin.ai-platform.example.com)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}