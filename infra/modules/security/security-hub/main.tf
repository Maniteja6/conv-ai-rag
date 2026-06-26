# ============================================================================
# modules/security/security-hub — account enablement
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "security/security-hub"
    ManagedBy   = "terraform"
  })
}

resource "aws_securityhub_account" "this" {
  enable_default_standards  = false # we enable explicitly in standards.tf
  auto_enable_controls      = var.auto_enable_controls
  control_finding_generator = "SECURITY_CONTROL"
}

# Ingest GuardDuty findings into Security Hub for a single pane of glass.
resource "aws_securityhub_product_subscription" "guardduty" {
  depends_on  = [aws_securityhub_account.this]
  product_arn = "arn:aws:securityhub:${var.region}::product/aws/guardduty"
}