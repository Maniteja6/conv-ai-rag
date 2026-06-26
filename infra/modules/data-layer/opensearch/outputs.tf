# ============================================================================
# modules/data-layer/opensearch — outputs
# ============================================================================

output "domain_arn" {
  description = "Domain ARN (feeds modules/security/iam opensearch_domain_arn)."
  value       = aws_opensearch_domain.this.arn
}

output "domain_name" {
  value = aws_opensearch_domain.this.domain_name
}

output "domain_endpoint" {
  description = "HTTPS endpoint for the retriever/embedding services."
  value       = aws_opensearch_domain.this.endpoint
}

output "dashboard_endpoint" {
  value = aws_opensearch_domain.this.dashboard_endpoint
}