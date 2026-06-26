# ============================================================================
# modules/edge-security/cloudfront — outputs
# ============================================================================

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN (for Shield Advanced protection)."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name (Route 53 alias target)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2)."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}