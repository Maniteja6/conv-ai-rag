# ============================================================================
# global/org-scp — Service Control Policies (AWS Organizations)
# Applied at the org/management account. Requires Organizations + the target
# OUs to exist. SCPs are guardrails: they cap what member accounts can do.
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_organizations_policy" "guardrails" {
  name        = "ai-platform-guardrails"
  description = "Baseline SCP guardrails for the AI platform OU."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp.json
}

resource "aws_organizations_policy_attachment" "guardrails" {
  for_each  = toset(var.target_ou_ids)
  policy_id = aws_organizations_policy.guardrails.id
  target_id = each.value
}

output "scp_policy_id" { value = aws_organizations_policy.guardrails.id }