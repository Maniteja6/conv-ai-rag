# ============================================================================
# modules/data-layer/aurora-postgresql — outputs
# ============================================================================

output "cluster_arn" {
  value = aws_rds_cluster.this.arn
}

output "cluster_identifier" {
  value = aws_rds_cluster.this.id
}

output "cluster_endpoint" {
  description = "Writer endpoint (direct; prefer proxy_endpoint from apps)."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for read-scaling."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint (apps connect here)."
  value       = try(aws_db_proxy.this[0].endpoint, null)
}

output "database_name" {
  value = aws_rds_cluster.this.database_name
}

output "port" {
  value = aws_rds_cluster.this.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master credentials secret."
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
}