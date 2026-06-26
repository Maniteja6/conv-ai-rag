# ============================================================================
# global/iam-baseline — account-wide IAM guardrails
#   * Mandatory permissions boundary for all human/CI principals
#   * Password policy
#   * Cross-account CI/CD deploy role
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { ManagedBy = "terraform", Scope = "global" } }
}

data "aws_caller_identity" "current" {}

# --- Account password policy ------------------------------------------------
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

# --- Permissions boundary (max permissions any created principal may have) --
data "aws_iam_policy_document" "boundary" {
  statement {
    sid       = "AllowServices"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
  statement {
    sid       = "DenyDangerousActions"
    effect    = "Deny"
    actions = [
      "organizations:LeaveOrganization",
      "account:CloseAccount",
      "iam:DeleteAccountPasswordPolicy",
      "iam:CreateAccountAlias",
    ]
    resources = ["*"]
  }
  # Deny disabling security services.
  statement {
    sid       = "ProtectSecurityServices"
    effect    = "Deny"
    actions = [
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "securityhub:DisableSecurityHub",
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "config:DeleteConfigurationRecorder",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "boundary" {
  name        = "platform-permissions-boundary"
  description = "Mandatory permissions boundary for all platform principals."
  policy      = data.aws_iam_policy_document.boundary.json
}

# --- GitHub Actions OIDC deploy role (CI/CD) -------------------------------
data "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_provider_arn != null ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  github_oidc_arn = var.create_github_oidc ? aws_iam_openid_connect_provider.github[0].arn : var.github_oidc_provider_arn
}

data "aws_iam_policy_document" "ci_assume" {
  count = local.github_oidc_arn != null ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "ci_deploy" {
  count                = local.github_oidc_arn != null ? 1 : 0
  name                 = "platform-ci-deploy"
  assume_role_policy   = data.aws_iam_policy_document.ci_assume[0].json
  permissions_boundary = aws_iam_policy.boundary.arn
}

resource "aws_iam_role_policy_attachment" "ci_deploy_admin" {
  count      = local.github_oidc_arn != null ? 1 : 0
  role       = aws_iam_role.ci_deploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess" # scope down for real prod
}

output "permissions_boundary_arn" { value = aws_iam_policy.boundary.arn }
output "ci_deploy_role_arn" { value = try(aws_iam_role.ci_deploy[0].arn, null) }
output "github_oidc_provider_arn" { value = local.github_oidc_arn }