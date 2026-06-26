# ============================================================================
# modules/networking/vpc-endpoints — outputs
# ============================================================================

output "endpoint_security_group_id" {
  description = "Security group ID guarding the interface endpoints."
  value       = aws_security_group.endpoints.id
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint short-name => endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns" {
  description = "Map of interface endpoint short-name => DNS entries."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID."
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB gateway endpoint ID (null if disabled)."
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}