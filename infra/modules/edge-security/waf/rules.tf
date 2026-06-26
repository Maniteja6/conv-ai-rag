# ============================================================================
# modules/edge-security/waf — custom rule definitions (non-managed)
# Currently the custom request inspection is folded into main.tf's web ACL.
# This file documents/extends with body-size and known-bad-input guards that
# aren't covered by managed groups.
# ============================================================================

locals {
  # Body size cap (bytes). Bedrock prompts can be large, so allow generous
  # payloads but block obvious abuse (> 1 MiB).
  max_body_size = 1048576
}

# Note: body-size and SQLi/XSS inspection are delivered primarily through the
# AWS managed rule groups (managed-rule-groups.tf): CommonRuleSet includes
# SizeRestrictions_BODY, plus KnownBadInputs and SQLiRuleSet. We intentionally
# rely on the maintained managed groups rather than hand-rolled signatures to
# reduce false positives against LLM payloads.