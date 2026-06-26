# ============================================================================
# modules/compute/alb — outputs
# ============================================================================

output "alb_arn" {
  description = "ALB ARN (for Shield Advanced + WAF association)."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name (CloudFront origin + Route 53 alias for WS host)."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (Route 53 alias target)."
  value       = aws_lb.this.zone_id
}

output "https_listener_arn" {
  description = "HTTPS listener ARN (controller attaches rules / TG bindings)."
  value       = aws_lb_listener.https.arn
}

output "http_target_group_arn" {
  value = aws_lb_target_group.http.arn
}

output "ws_target_group_arn" {
  value = aws_lb_target_group.ws.arn
}