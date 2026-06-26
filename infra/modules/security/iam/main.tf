# ============================================================================
# modules/security/iam — shared locals & data sources
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "security/iam"
    ManagedBy   = "terraform"
  })

  irsa_enabled = var.oidc_provider_arn != null && var.oidc_provider_url != null
}