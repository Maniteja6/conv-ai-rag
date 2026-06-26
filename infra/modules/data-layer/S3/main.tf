# ============================================================================
# modules/data-layer/s3 — locals & account public access block
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  # Globally-unique bucket names include the account id.
  document_bucket = "${local.name}-documents-${var.account_id}"
  logs_bucket     = "${local.name}-logs-${var.account_id}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "data-layer/s3"
    ManagedBy   = "terraform"
  })
}