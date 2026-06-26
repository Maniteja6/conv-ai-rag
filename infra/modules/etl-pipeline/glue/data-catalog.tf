# ============================================================================
# modules/etl-pipeline/glue — Data Catalog databases
# ============================================================================

resource "aws_glue_catalog_database" "rag" {
  name        = replace("${local.name}_rag_catalog", "-", "_")
  description = "Catalog for RAG document metadata, chunks, and embeddings lineage."

  tags = local.tags
}

resource "aws_glue_catalog_database" "structured" {
  name        = replace("${local.name}_structured", "-", "_")
  description = "Catalog for structured data sources queried by text-to-sql-service."

  tags = local.tags
}

# --- Catalog encryption settings -------------------------------------------
resource "aws_glue_data_catalog_encryption_settings" "this" {
  count = var.kms_key_arn != null ? 1 : 0

  data_catalog_encryption_settings {
    connection_password_encryption {
      return_connection_password_encrypted = true
      aws_kms_key_id                        = var.kms_key_arn
    }
    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = var.kms_key_arn
    }
  }
}