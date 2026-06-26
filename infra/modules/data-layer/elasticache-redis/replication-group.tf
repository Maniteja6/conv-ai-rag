# ============================================================================
# modules/data-layer/elasticache-redis — replication group
# ============================================================================

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${local.name}-redis"
  description          = "Redis replication group for ${local.name}."

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = var.subnet_group_name
  security_group_ids   = [var.security_group_id]

  # Cluster-mode topology.
  num_node_groups         = var.num_node_groups
  replicas_per_node_group = var.replicas_per_node_group

  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.automatic_failover_enabled

  # Encryption everywhere.
  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  transit_encryption_enabled = true
  auth_token = var.auth_token_secret_arn != null ? jsondecode(data.aws_secretsmanager_secret_version.auth[0].secret_string)["value"] : null

  # Backups.
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "sun:03:00-sun:04:00"

  notification_topic_arn = var.sns_topic_arn
  apply_immediately      = false
  auto_minor_version_upgrade = true

  tags = merge(local.tags, { Name = "${local.name}-redis" })

  lifecycle {
    ignore_changes = [auth_token]
  }
}