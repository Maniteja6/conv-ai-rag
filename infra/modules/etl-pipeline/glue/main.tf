# ============================================================================
# modules/etl-pipeline/glue — security config + locals
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "etl-pipeline/glue"
    ManagedBy   = "terraform"
  })
}

# --- Glue security configuration (encrypt at rest + CloudWatch) -------------
resource "aws_glue_security_configuration" "this" {
  count = var.kms_key_arn != null ? 1 : 0
  name  = "${local.name}-glue-sec"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = var.kms_key_arn
    }
    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = var.kms_key_arn
    }
    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = var.kms_key_arn
    }
  }
}