# ============================================================================
# modules/data-layer/elasticache-redis — locals & auth token
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "data-layer/elasticache-redis"
    ManagedBy   = "terraform"
  })

  cluster_mode_enabled = var.num_node_groups > 1
}

data "aws_secretsmanager_secret_version" "auth" {
  count     = var.auth_token_secret_arn != null ? 1 : 0
  secret_id = var.auth_token_secret_arn
}