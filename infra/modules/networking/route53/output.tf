output "public_zone_id" {
  description = "Public hosted zone ID."
  value       = try(aws_route53_zone.public[0].zone_id, null)
}

output "public_zone_name_servers" {
  description = "Name servers for the public zone (set these at your registrar)."
  value       = try(aws_route53_zone.public[0].name_servers, [])
}

output "private_zone_id" {
  description = "Private hosted zone ID."
  value       = try(aws_route53_zone.private[0].zone_id, null)
}

output "health_check_id" {
  description = "Primary Route 53 health check ID."
  value       = try(aws_route53_health_check.primary[0].id, null)
}