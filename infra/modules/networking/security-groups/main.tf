# ============================================================================
# modules/networking/security-groups — shared locals
# Security groups are split across files by tier:
#   alb-sg.tf  -> public ALB
#   eks-sg.tf  -> EKS nodes / pods
#   data-sg.tf -> Aurora, OpenSearch, Redis
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "networking/security-groups"
    ManagedBy   = "terraform"
  })
}