# ============================================================================
# modules/observability/xray — outputs
# ============================================================================

output "default_sampling_rule_arn" {
  value = aws_xray_sampling_rule.default.arn
}

output "error_group_arn" {
  value = aws_xray_group.errors.arn
}