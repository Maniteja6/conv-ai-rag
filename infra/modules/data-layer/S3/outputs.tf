# ============================================================================
# modules/data-layer/s3 — outputs
# ============================================================================

output "document_bucket_id" {
  value = aws_s3_bucket.documents.id
}

output "document_bucket_arn" {
  description = "Feeds modules/security/iam document_bucket_arn."
  value       = aws_s3_bucket.documents.arn
}

output "document_bucket_domain_name" {
  value = aws_s3_bucket.documents.bucket_regional_domain_name
}

output "logs_bucket_id" {
  value = try(aws_s3_bucket.logs[0].id, null)
}

output "logs_bucket_arn" {
  value = try(aws_s3_bucket.logs[0].arn, null)
}

output "logs_bucket_domain_name" {
  description = "For CloudFront/ALB access log configuration."
  value       = try(aws_s3_bucket.logs[0].bucket_domain_name, null)
}