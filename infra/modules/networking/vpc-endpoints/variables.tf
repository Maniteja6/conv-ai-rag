# ============================================================================
# modules/networking/vpc-endpoints — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to attach endpoints to."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR (for the endpoint security group ingress)."
  type        = string
}

variable "region" {
  description = "AWS region (for building service names)."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Subnets for interface endpoints (EKS app tier)."
  type        = list(string)
}

variable "gateway_route_table_ids" {
  description = "Route table IDs to associate with gateway endpoints (S3/DynamoDB)."
  type        = list(string)
}

variable "enable_dynamodb_endpoint" {
  description = "Create a DynamoDB gateway endpoint."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}