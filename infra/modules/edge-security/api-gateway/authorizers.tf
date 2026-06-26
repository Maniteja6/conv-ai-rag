# ============================================================================
# modules/edge-security/api-gateway — JWT / Cognito authorizers
# ============================================================================

locals {
  # Prefer Cognito if a user pool is supplied; else a generic JWT issuer.
  use_cognito = var.cognito_user_pool_arn != null
  use_jwt     = !local.use_cognito && var.jwt_issuer != null

  authorizer_enabled = local.use_cognito || local.use_jwt
  authorizer_type    = local.authorizer_enabled ? "JWT" : "NONE"
  authorizer_id      = local.authorizer_enabled ? aws_apigatewayv2_authorizer.jwt[0].id : null

  # Build the issuer URL. Cognito issuer is derived from the pool ARN region/id.
  cognito_issuer = local.use_cognito ? format(
    "https://cognito-idp.%s.amazonaws.com/%s",
    split(":", var.cognito_user_pool_arn)[3],
    element(split("/", var.cognito_user_pool_arn), 1)
  ) : null

  effective_issuer    = local.use_cognito ? local.cognito_issuer : var.jwt_issuer
  effective_audiences = local.use_cognito ? ["*"] : var.jwt_audiences
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count            = local.authorizer_enabled ? 1 : 0
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name}-jwt-authorizer"

  jwt_configuration {
    issuer   = local.effective_issuer
    audience = local.effective_audiences
  }
}