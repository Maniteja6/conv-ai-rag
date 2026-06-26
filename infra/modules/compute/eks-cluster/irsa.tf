# ============================================================================
# modules/compute/eks-cluster — cluster-scoped IRSA roles for core addons
# (Application service IRSA lives in modules/security/iam; these are the
#  controllers the cluster itself needs: EBS CSI, VPC CNI, etc.)
# ============================================================================

locals {
  oidc_provider_url = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}

# Generic IRSA trust-policy builder for addon service accounts.
data "aws_iam_policy_document" "addon_irsa" {
  for_each = {
    ebs_csi    = { namespace = "kube-system", sa = "ebs-csi-controller-sa" }
    vpc_cni    = { namespace = "kube-system", sa = "aws-node" }
    coredns    = { namespace = "kube-system", sa = "coredns" }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.sa}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# --- EBS CSI driver role ----------------------------------------------------
resource "aws_iam_role" "ebs_csi" {
  name               = "${local.name}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.addon_irsa["ebs_csi"].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Allow the EBS CSI role to use the EBS CMK.
data "aws_iam_policy_document" "ebs_csi_kms" {
  count = var.ebs_kms_key_arn != null ? 1 : 0

  statement {
    sid     = "EbsKmsUse"
    effect  = "Allow"
    actions = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = [var.ebs_kms_key_arn]
  }
  statement {
    sid       = "EbsKmsGrant"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = [var.ebs_kms_key_arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy" "ebs_csi_kms" {
  count  = var.ebs_kms_key_arn != null ? 1 : 0
  name   = "${local.name}-ebs-csi-kms"
  role   = aws_iam_role.ebs_csi.id
  policy = data.aws_iam_policy_document.ebs_csi_kms[0].json
}

# --- VPC CNI role -----------------------------------------------------------
resource "aws_iam_role" "vpc_cni" {
  name               = "${local.name}-vpc-cni"
  assume_role_policy = data.aws_iam_policy_document.addon_irsa["vpc_cni"].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}