# ============================================================================
# modules/edge-security/waf — AWS managed rule groups
# Consumed by the dynamic "rule" block in main.tf.
# Excluded rules are set to COUNT (not block) to avoid false positives on
# legitimate LLM/RAG payloads while still gaining visibility.
# ============================================================================

locals {
  managed_rule_groups = [
    {
      name           = "AWSManagedRulesCommonRuleSet"
      priority       = 20
      # SizeRestrictions_BODY can clip large prompts; we monitor instead of block.
      excluded_rules = ["SizeRestrictions_BODY", "CrossSiteScripting_BODY"]
    },
    {
      name           = "AWSManagedRulesKnownBadInputsRuleSet"
      priority       = 21
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesSQLiRuleSet"
      priority       = 22
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesAmazonIpReputationList"
      priority       = 23
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesAnonymousIpList"
      priority       = 24
      # Allow legit VPN/hosting traffic; count only.
      excluded_rules = ["HostingProviderIPList"]
    },
    {
      name           = "AWSManagedRulesBotControlRuleSet"
      priority       = 25
      excluded_rules = []
    },
  ]
}