# ============================================================================
# modules/data-layer/aurora-postgresql — cluster + instances
# ============================================================================

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${local.name}-aurora"
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  db_subnet_group_name            = var.db_subnet_group_name
  vpc_security_group_ids          = [var.security_group_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  # Password management: RDS-managed (rotates automatically) OR from secret.
  manage_master_user_password = var.manage_master_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_password ? var.kms_key_arn : null
  master_password = (
    !var.manage_master_password && var.master_password_secret_arn != null
    ? jsondecode(data.aws_secretsmanager_secret_version.master[0].secret_string)["value"]
    : null
  )

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  copy_tags_to_snapshot        = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-aurora-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.use_serverless_v2 ? [1] : []
    content {
      min_capacity = var.serverless_min_acu
      max_capacity = var.serverless_max_acu
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-aurora" })

  lifecycle {
    ignore_changes = [final_snapshot_identifier, master_password]
  }
}

# --- Writer instance --------------------------------------------------------
resource "aws_rds_cluster_instance" "writer" {
  identifier                   = "${local.name}-aurora-writer"
  cluster_identifier           = aws_rds_cluster.this.id
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  instance_class               = local.writer_instance_class
  db_parameter_group_name      = aws_db_parameter_group.this.name
  db_subnet_group_name         = var.db_subnet_group_name
  performance_insights_enabled = true
  performance_insights_kms_key_id = var.kms_key_arn
  monitoring_interval          = var.monitoring_role_arn != null ? 60 : 0
  monitoring_role_arn          = var.monitoring_role_arn
  auto_minor_version_upgrade   = true
  promotion_tier               = 0

  tags = merge(local.tags, { Name = "${local.name}-aurora-writer", Role = "writer" })
}

# --- Reader instances -------------------------------------------------------
resource "aws_rds_cluster_instance" "reader" {
  count                        = var.reader_count
  identifier                   = "${local.name}-aurora-reader-${count.index}"
  cluster_identifier           = aws_rds_cluster.this.id
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  instance_class               = local.writer_instance_class
  db_parameter_group_name      = aws_db_parameter_group.this.name
  db_subnet_group_name         = var.db_subnet_group_name
  performance_insights_enabled = true
  performance_insights_kms_key_id = var.kms_key_arn
  monitoring_interval          = var.monitoring_role_arn != null ? 60 : 0
  monitoring_role_arn          = var.monitoring_role_arn
  auto_minor_version_upgrade   = true
  promotion_tier               = count.index + 1

  tags = merge(local.tags, { Name = "${local.name}-aurora-reader-${count.index}", Role = "reader" })
}