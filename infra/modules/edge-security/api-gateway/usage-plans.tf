# ============================================================================
# modules/edge-security/api-gateway — per-consumer throttling
# HTTP APIs (v2) don't use REST-style usage plans/API keys. Per-consumer
# rate control is implemented with stage-level + per-route throttling and
# (optionally) Lambda authorizer rate metadata. For partner key management,
# we model tiers as per-route throttle settings.
# ============================================================================

variable "route_throttle_overrides" {
  description = "Per-route throttle overrides: route_key => { rate, burst }."
  type = map(object({
    rate  = number
    burst = number
  }))
  default = {}
}

resource "aws_apigatewayv2_route_response" "noop" {
  # Placeholder to keep route response wiring explicit when needed.
  count              = 0
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = try(aws_apigatewayv2_route.default[0].id, "")
  route_response_key = "$default"
}

# Apply per-route throttle overrides on the stage.
resource "aws_apigatewayv2_stage" "tiered" {
  count       = length(var.route_throttle_overrides) > 0 ? 1 : 0
  api_id      = aws_apigatewayv2_api.this.id
  name        = "${var.environment}-tiered"
  auto_deploy = true

  dynamic "route_settings" {
    for_each = var.route_throttle_overrides
    content {
      route_key              = route_settings.key
      throttling_rate_limit  = route_settings.value.rate
      throttling_burst_limit = route_settings.value.burst
    }
  }

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }

  tags = local.tags
}