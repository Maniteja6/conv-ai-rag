# ============================================================================
# modules/security/secrets-manager — shared locals
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "security/secrets-manager"
    ManagedBy   = "terraform"
  })
}