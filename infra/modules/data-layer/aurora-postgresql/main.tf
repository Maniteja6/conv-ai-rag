# ============================================================================
# modules/data-layer/aurora-postgresql — locals, master secret wiring
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "data-layer/aurora-postgresql"
    ManagedBy   = "terraform"
  })

  # When use_serverless_v2, instances use the special db.serverless class and
  # the cluster carries serverlessv2_scaling_configuration.
  writer_instance_class = var.use_serverless_v2 ? "db.serverless" : var.instance_class
}

# Read the master password from Secrets Manager when not RDS-managed.
data "aws_secretsmanager_secret_version" "master" {
  count     = !var.manage_master_password && var.master_password_secret_arn != null ? 1 : 0
  secret_id = var.master_password_secret_arn
}