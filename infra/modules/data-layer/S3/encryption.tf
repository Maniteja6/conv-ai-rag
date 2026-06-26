# ============================================================================
# modules/data-layer/s3 — default SSE-KMS encryption
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true # reduces KMS API costs
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enable_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      # Log-delivery (ALB/CloudFront) requires SSE-S3 (AES256), not KMS.
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}