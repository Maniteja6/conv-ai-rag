# ============================================================================
# modules/security/kms — outputs (key ARNs consumed across the platform)
# ============================================================================

output "key_arns" {
  description = "Map of domain => KMS key ARN."
  value       = { for k, v in aws_kms_key.this : k => v.arn }
}

output "key_ids" {
  description = "Map of domain => KMS key ID."
  value       = { for k, v in aws_kms_key.this : k => v.key_id }
}

output "alias_names" {
  description = "Map of domain => alias name."
  value       = { for k, v in aws_kms_alias.this : k => v.name }
}

# Convenience single-key accessors for common consumers.
output "rds_key_arn" { value = aws_kms_key.this["rds"].arn }
output "opensearch_key_arn" { value = aws_kms_key.this["opensearch"].arn }
output "redis_key_arn" { value = aws_kms_key.this["redis"].arn }
output "dynamodb_key_arn" { value = aws_kms_key.this["dynamodb"].arn }
output "s3_key_arn" { value = aws_kms_key.this["s3"].arn }
output "secrets_key_arn" { value = aws_kms_key.this["secrets"].arn }
output "logs_key_arn" { value = aws_kms_key.this["logs"].arn }
output "ebs_key_arn" { value = aws_kms_key.this["ebs"].arn }
output "backup_key_arn" { value = aws_kms_key.this["backup"].arn }