# ============================================================================
# modules/security/security-hub — outputs
# ============================================================================

output "account_id" {
  description = "Security Hub account enablement resource ID."
  value       = aws_securityhub_account.this.id
}

output "enabled_standards" {
  description = "List of enabled standard ARNs."
  value = compact([
    try(aws_securityhub_standards_subscription.cis[0].standards_arn, ""),
    try(aws_securityhub_standards_subscription.aws_foundational[0].standards_arn, ""),
    try(aws_securityhub_standards_subscription.pci[0].standards_arn, ""),
  ])
}