# ============================================================================
# environments/prod — root outputs
# ============================================================================

output "vpc_id" { value = module.vpc.vpc_id }
output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }

output "alb_dns_name" { value = module.alb.alb_dns_name }
output "cloudfront_domain" { value = module.cloudfront.domain_name }

output "aurora_proxy_endpoint" { value = module.aurora.proxy_endpoint }
output "opensearch_endpoint" { value = module.opensearch.domain_endpoint }
output "redis_primary_endpoint" { value = module.redis.primary_endpoint }

output "irsa_role_arns" {
  description = "Annotate K8s service accounts with these."
  value       = module.iam.irsa_role_arns
}

output "bedrock_guardrail_id" { value = module.bedrock.guardrail_id }
output "alerts_topic_arn" { value = module.cloudwatch.alerts_topic_arn }
output "document_bucket" { value = module.s3.document_bucket_id }