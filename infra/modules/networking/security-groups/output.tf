# ============================================================================
# modules/networking/security-groups — outputs
# ============================================================================

output "alb_security_group_id" {
  description = "Public ALB security group ID."
  value       = aws_security_group.alb.id
}

output "eks_nodes_security_group_id" {
  description = "EKS worker node security group ID."
  value       = aws_security_group.eks_nodes.id
}

output "aurora_security_group_id" {
  description = "Aurora PostgreSQL security group ID."
  value       = aws_security_group.aurora.id
}

output "opensearch_security_group_id" {
  description = "OpenSearch security group ID."
  value       = aws_security_group.opensearch.id
}

output "redis_security_group_id" {
  description = "ElastiCache Redis security group ID."
  value       = aws_security_group.redis.id
}