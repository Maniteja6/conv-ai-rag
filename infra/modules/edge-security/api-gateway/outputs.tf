# ============================================================================
# modules/edge-security/api-gateway — outputs
# ============================================================================

output "api_id" {
  description = "HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Invoke URL for the HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_arn" {
  description = "Stage ARN (for WAF association / monitoring)."
  value       = aws_apigatewayv2_stage.this.arn
}

output "stage_invoke_url" {
  description = "Full invoke URL including stage."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "vpc_link_id" {
  description = "VPC Link ID (null if no NLB target)."
  value       = try(aws_apigatewayv2_vpc_link.this[0].id, null)
}

output "authorizer_id" {
  description = "JWT authorizer ID (null if unauthenticated)."
  value       = local.authorizer_id
}