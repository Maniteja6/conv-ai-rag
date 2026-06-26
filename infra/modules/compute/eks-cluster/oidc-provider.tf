# ============================================================================
# modules/compute/eks-cluster — IAM OIDC provider (enables IRSA)
# These outputs feed modules/security/iam (oidc_provider_arn / _url) so the
# per-service IRSA roles can finally be created.
# ============================================================================

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = merge(local.tags, { Name = "${local.name}-oidc" })
}