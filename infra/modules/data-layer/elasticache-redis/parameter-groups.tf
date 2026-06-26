# ============================================================================
# modules/data-layer/elasticache-redis — parameter group
# ============================================================================

resource "aws_elasticache_parameter_group" "this" {
  name        = "${local.name}-redis"
  family      = "redis7"
  description = "Redis params for ${local.name}."

  # Evict least-recently-used keys with TTL when memory is full (cache use).
  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  # Enable keyspace notifications for session expiry events.
  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  tags = local.tags
}