# ============================================================================
# modules/etl-pipeline/glue — crawlers
# ============================================================================

# --- Crawl document metadata / chunk manifests in S3 -----------------------
resource "aws_glue_crawler" "documents" {
  name          = "${local.name}-documents-crawler"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.rag.name
  description   = "Crawls parsed document + chunk metadata in S3."
  schedule      = var.crawler_schedule

  security_configuration = try(aws_glue_security_configuration.this[0].name, null)

  s3_target {
    path = "s3://${var.document_bucket_id}/parsed/"
  }
  s3_target {
    path = "s3://${var.document_bucket_id}/chunks/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = merge(local.tags, { Name = "${local.name}-documents-crawler" })
}