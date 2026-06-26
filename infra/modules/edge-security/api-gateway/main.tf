# ============================================================================
# modules/edge-security/api-gateway — HTTP API + VPC Link + stage
# Uses API Gateway v2 (HTTP API): lower cost/latency, native JWT authorizers,
# and WebSocket support if you later add a $connect/$disconnect API.
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "edge-security/api-gateway"
    ManagedBy   = "terraform"
  })
}

# --- VPC Link to reach private EKS services --------------------------------
resource "aws_apigatewayv2_vpc_link" "this" {
  count              = var.nlb_listener_arn != null ? 1 : 0
  name               = "${local.name}-vpc-link"
  subnet_ids         = var.vpc_link_subnet_ids
  security_group_ids = var.vpc_link_security_group_ids
  tags               = local.tags
}

# --- HTTP API ---------------------------------------------------------------
resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-http-api"
  protocol_type = "HTTP"
  description   = "Programmatic API surface for ${var.project}."

  cors_configuration {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
    allow_headers     = ["authorization", "content-type", "x-api-key"]
    expose_headers    = ["x-request-id"]
    max_age           = 300
    allow_credentials = false
  }

  tags = local.tags
}

# --- Integration: proxy to internal NLB via VPC Link -----------------------
resource "aws_apigatewayv2_integration" "proxy" {
  count            = var.nlb_listener_arn != null ? 1 : 0
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.nlb_listener_arn

  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.this[0].id
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

# --- Default route (protected by authorizer) -------------------------------
resource "aws_apigatewayv2_route" "default" {
  count              = var.nlb_listener_arn != null ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.proxy[0].id}"
  authorization_type = local.authorizer_type
  authorizer_id      = local.authorizer_id
}

# --- Health route (no auth) -------------------------------------------------
resource "aws_apigatewayv2_route" "health" {
  count     = var.nlb_listener_arn != null ? 1 : 0
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.proxy[0].id}"
}

# --- Access logging ---------------------------------------------------------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}

# --- Stage ------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.environment
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
    detailed_metrics_enabled = true
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      authError        = "$context.authorizer.error"
    })
  }

  tags = local.tags
}

# --- WAF association --------------------------------------------------------
resource "aws_wafv2_web_acl_association" "api" {
  count        = var.web_acl_arn != null ? 1 : 0
  resource_arn = aws_apigatewayv2_stage.this.arn
  web_acl_arn  = var.web_acl_arn
}