# ============================================================================
# modules/edge-security/waf — rate-based rule definitions
# Consumed by the dynamic "rule" block in main.tf.
# ============================================================================

locals {
  rate_limit_rules = [
    {
      name        = "global-rate-limit"
      priority    = 10
      limit       = var.rate_limit_per_5min
      path_prefix = null
    },
    {
      name        = "api-rate-limit"
      priority    = 11
      limit       = var.rate_limit_api_per_5min
      path_prefix = "/api/"
    },
  ]
}