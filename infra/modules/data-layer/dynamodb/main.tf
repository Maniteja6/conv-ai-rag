# ============================================================================
# modules/data-layer/dynamodb — locals
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "data-layer/dynamodb"
    ManagedBy   = "terraform"
  })
}