# ============================================================================
# infrastructure — provider configuration
# ----------------------------------------------------------------------------
# Two AWS providers:
#   * default     -> the workload region (e.g. us-east-1)
#   * us_east_1   -> required for CloudFront WAF (WAFv2 CLOUDFRONT scope) and
#                    ACM certs consumed by CloudFront, which must live in
#                    us-east-1 regardless of the workload region.
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "enterprise-ai-rag-platform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "enterprise-ai-rag-platform"
    }
  }
}

# Kubernetes / Helm providers are configured in the environment root once the
# EKS cluster endpoint + auth are known (data sources on the cluster). They are
# declared here so child modules can rely on them being present.
data "aws_eks_cluster_auth" "this" {
  count = var.eks_cluster_name != null ? 1 : 0
  name  = var.eks_cluster_name
}