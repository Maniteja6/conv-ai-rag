# ============================================================================
# modules/data-layer/elasticache-redis — outputs
# ============================================================================

output "primary_endpoint" {
  description = "Primary endpoint (cluster-mode-disabled writes)."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  value = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "configuration_endpoint" {
  description = "Configuration endpoint (cluster-mode-enabled clients)."
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "port" {
  value = 6379
}

output "replication_group_id" {
  value = aws_elasticache_replication_group.this.id
}