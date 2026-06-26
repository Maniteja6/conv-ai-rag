# ============================================================================
# modules/etl-pipeline/glue — outputs
# ============================================================================

output "rag_database_name" {
  value = aws_glue_catalog_database.rag.name
}

output "structured_database_name" {
  description = "Glue DB for structured sources (text-to-sql-service uses this)."
  value       = aws_glue_catalog_database.structured.name
}

output "documents_crawler_name" {
  value = aws_glue_crawler.documents.name
}

output "security_configuration_name" {
  value = try(aws_glue_security_configuration.this[0].name, null)
}