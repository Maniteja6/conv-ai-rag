# ============================================================================
# modules/security/kms — shared locals
# One customer-managed key per data domain so blast radius is contained and
# key policies can be scoped to the specific service principals that use them.
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "security/kms"
    ManagedBy   = "terraform"
  })

  # Domains that each get a dedicated CMK + alias.
  key_domains = {
    rds        = "Aurora PostgreSQL encryption"
    opensearch = "OpenSearch domain encryption"
    redis      = "ElastiCache Redis encryption"
    dynamodb   = "DynamoDB table encryption"
    s3         = "S3 document bucket encryption"
    secrets    = "Secrets Manager secret encryption"
    logs       = "CloudWatch Logs encryption"
    ebs        = "EKS node EBS volume encryption"
    sns        = "SNS topic encryption"
    backup     = "AWS Backup vault encryption"
  }
}