# ============================================================================
# modules/data-layer/opensearch — locals & service-linked role
# ============================================================================

locals {
  name        = "${var.project}-${var.environment}"
  domain_name = substr("${var.project}-${var.environment}", 0, 28) # domain name <= 28 chars

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "data-layer/opensearch"
    ManagedBy   = "terraform"
  })
}

# Service-linked role for OpenSearch VPC domains (idempotent; ignore if exists).
resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_service_linked_role ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}

variable "create_service_linked_role" {
  description = "Create the OpenSearch service-linked role (set false if it already exists in the account)."
  type        = bool
  default     = false
}

# Read master creds if FGAC internal user DB is used.
data "aws_secretsmanager_secret_version" "master" {
  count     = var.master_user_secret_arn != null ? 1 : 0
  secret_id = var.master_user_secret_arn
}