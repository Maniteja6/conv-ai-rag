# ============================================================================
# modules/compute/eks-node-groups — Karpenter IAM (controller + node role)
# The Karpenter Helm chart + NodePool/EC2NodeClass CRDs live in
# kubernetes/addons/karpenter; here we provision the AWS-side IAM it needs.
# ============================================================================

locals {
  karpenter_enabled = var.enable_karpenter && var.oidc_provider_arn != null
  oidc_url          = var.oidc_provider_url
}

# --- Karpenter controller IRSA role ----------------------------------------
data "aws_iam_policy_document" "karpenter_controller_assume" {
  count = local.karpenter_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count              = local.karpenter_enabled ? 1 : 0
  name               = "${local.name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "karpenter_controller" {
  count = local.karpenter_enabled ? 1 : 0

  statement {
    sid    = "EC2Provisioning"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate", "ec2:CreateFleet", "ec2:RunInstances",
      "ec2:CreateTags", "ec2:TerminateInstances", "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates", "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets",
      "ec2:DescribeImages", "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassNodeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.node.arn]
  }

  statement {
    sid       = "EKSClusterRead"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    sid    = "InstanceProfile"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile", "iam:TagInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PricingAndSSM"
    effect    = "Allow"
    actions   = ["pricing:GetProducts", "ssm:GetParameter"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count  = local.karpenter_enabled ? 1 : 0
  name   = "${local.name}-karpenter-controller"
  role   = aws_iam_role.karpenter_controller[0].id
  policy = data.aws_iam_policy_document.karpenter_controller[0].json
}

# --- Interruption queue (Spot rebalance / termination handling) ------------
resource "aws_sqs_queue" "karpenter_interruption" {
  count                     = local.karpenter_enabled ? 1 : 0
  name                      = "${local.name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = local.karpenter_enabled ? {
    spot_interruption = { source = "aws.ec2", detail-type = "EC2 Spot Instance Interruption Warning" }
    rebalance         = { source = "aws.ec2", detail-type = "EC2 Instance Rebalance Recommendation" }
    state_change      = { source = "aws.ec2", detail-type = "EC2 Instance State-change Notification" }
  } : {}

  name          = "${local.name}-karpenter-${each.key}"
  event_pattern = jsonencode({ source = [each.value.source], "detail-type" = [each.value["detail-type"]] })
  tags          = local.tags
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each  = aws_cloudwatch_event_rule.karpenter_interruption
  rule      = each.value.name
  target_id = "karpenter"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}