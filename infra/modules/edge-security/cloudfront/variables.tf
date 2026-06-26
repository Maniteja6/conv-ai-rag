# ============================================================================
# modules/edge-security/cloudfront — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "aliases" {
  description = "CNAMEs for the distribution (e.g. [ai-platform.example.com])."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN (MUST be in us-east-1 for CloudFront). Null = default cert."
  type        = string
  default     = null
}

variable "alb_domain_name" {
  description = "Public ALB DNS name (primary origin for HTTP/REST + UI)."
  type        = string
}

variable "web_acl_arn" {
  description = "CLOUDFRONT-scoped WAF web ACL ARN."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 | 200 | All)."
  type        = string
  default     = "PriceClass_100"
}

variable "minimum_protocol_version" {
  type    = string
  default = "TLSv1.2_2021"
}

variable "logging_bucket_domain" {
  description = "S3 bucket domain for CloudFront access logs (optional)."
  type        = string
  default     = null
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "custom_origin_header_secret" {
  description = "Shared secret header value sent to origin so ALB can reject non-CloudFront traffic."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}