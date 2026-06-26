# ============================================================================
# modules/edge-security/shield-advanced — outputs
# ============================================================================

output "protection_ids" {
  description = "Map of logical name => Shield protection ID."
  value       = { for k, v in aws_shield_protection.this : k => v.id }
}

output "protected_resource_arns" {
  description = "ARNs currently protected by Shield Advanced."
  value       = [for v in aws_shield_protection.this : v.resource_arn]
}