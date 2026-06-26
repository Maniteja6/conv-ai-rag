# ============================================================================
# modules/etl-pipeline/lambda-etl — OpenSearch index loader
# Reads embeddings + chunk text + metadata, bulk-upserts into the k-NN vector
# index. Idempotent on document_id+chunk_id so re-runs don't duplicate.
# ============================================================================

resource "aws_lambda_function" "opensearch_loader" {
  function_name = "${local.name}-opensearch-index-loader"
  role          = var.execution_role_arn
  runtime       = var.runtime
  architectures = [var.architecture]
  handler       = "handler.handler"
  filename      = data.archive_file.function["opensearch-index-loader"].output_path
  source_code_hash = data.archive_file.function["opensearch-index-loader"].output_base64sha256
  layers        = local.layer_arns

  memory_size = var.function_config["opensearch-index-loader"].memory_mb
  timeout     = var.function_config["opensearch-index-loader"].timeout_sec

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(local.common_env, {
      DOCUMENT_BUCKET      = var.document_bucket_id
      OPENSEARCH_ENDPOINT  = var.opensearch_endpoint
      OPENSEARCH_INDEX     = var.opensearch_index
      EMBEDDING_DIMENSIONS = tostring(var.embedding_dimensions)
      BULK_BATCH_SIZE      = "500"
    })
  }

  dynamic "dead_letter_config" {
    for_each = var.dlq_arn != null ? [1] : []
    content {
      target_arn = var.dlq_arn
    }
  }

  kms_key_arn = var.kms_key_arn
  tracing_config {
    mode = "Active"
  }

  tags = merge(local.tags, { Name = "${local.name}-opensearch-index-loader", Stage = "4-load" })

  depends_on = [aws_cloudwatch_log_group.function]
}