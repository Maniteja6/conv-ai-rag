# ============================================================================
# modules/data-layer/s3 — RAG document bucket (source docs for ingestion)
# ============================================================================

resource "aws_s3_bucket" "documents" {
  bucket        = local.document_bucket
  force_destroy = var.force_destroy
  tags          = merge(local.tags, { Name = local.document_bucket, DataClass = "confidential" })
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Access logging -> logs bucket.
resource "aws_s3_bucket_logging" "documents" {
  count         = var.enable_access_logs_bucket ? 1 : 0
  bucket        = aws_s3_bucket.documents.id
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3/documents/"
}

# Enforce TLS + deny unencrypted puts.
data "aws_iam_policy_document" "documents" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.documents.arn, "${aws_s3_bucket.documents.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.documents.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id
  policy = data.aws_iam_policy_document.documents.json
}

# --- Logs bucket ------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  count         = var.enable_access_logs_bucket ? 1 : 0
  bucket        = local.logs_bucket
  force_destroy = var.force_destroy
  tags          = merge(local.tags, { Name = local.logs_bucket, DataClass = "internal" })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count                   = var.enable_access_logs_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.enable_access_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred" # log delivery needs ACLs
  }
}