variable "aws_region" { type = string, default = "us-east-1" }
variable "create_github_oidc" { type = bool, default = true }
variable "github_oidc_provider_arn" { type = string, default = null }
variable "github_org" { type = string }
variable "github_repo" { type = string, default = "enterprise-ai-rag-platform" }