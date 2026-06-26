# ============================================================================
# modules/observability/cloudwatch — outputs
# These ARNs satisfy the deferred sns_topic_arn inputs across the platform.
# ============================================================================

output "alerts_topic_arn" {
  description = "SNS topic for general alerts (RDS events, GuardDuty, Redis, alarms)."
  value       = aws_sns_topic.alerts.arn
}

output "critical_topic_arn" {
  description = "SNS topic for sev-1 / paging alerts."
  value       = aws_sns_topic.critical.arn
}

output "application_log_group_name" {
  value = aws_cloudwatch_log_group.application.name
}

output "audit_log_group_name" {
  value = aws_cloudwatch_log_group.audit.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.platform.dashboard_name
}