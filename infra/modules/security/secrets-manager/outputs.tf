# ============================================================================
# modules/security/secrets-manager — outputs
# ============================================================================

output "secret_arns" {
  description = "Map of logical name => secret ARN."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_names" {
  description = "Map of logical name => full secret name (for external-secrets refs)."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "all_secret_arns" {
  description = "Flat list of all secret ARNs (for IAM policy scoping)."
  value       = [for v in aws_secretsmanager_secret.this : v.arn]
}