# ============================================================================
# modules/edge-security/waf — outputs
# ============================================================================

output "web_acl_arn" {
  description = "Web ACL ARN (associate with CloudFront or ALB/API Gateway)."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "Web ACL ID."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  value = aws_wafv2_web_acl.this.name
}

output "log_group_arn" {
  description = "WAF log group ARN (null if logging disabled)."
  value       = try(aws_cloudwatch_log_group.waf[0].arn, null)
}