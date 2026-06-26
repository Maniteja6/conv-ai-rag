# ============================================================================
# modules/data-layer/aurora-postgresql — cluster & instance parameter groups
# ============================================================================

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${local.name}-aurora-cluster"
  family      = "aurora-postgresql16"
  description = "Cluster params for ${local.name} Aurora PostgreSQL."

  # Force TLS for all connections.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Log slow queries (>1s) for observability.
  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  # pgvector + common extensions preloaded (text-to-sql, RAG metadata).
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_cron"
    apply_method = "pending-reboot"
  }

  tags = local.tags
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.name}-aurora-instance"
  family      = "aurora-postgresql16"
  description = "Instance params for ${local.name} Aurora PostgreSQL."

  parameter {
    name  = "log_rotation_age"
    value = "60"
  }

  tags = local.tags
}