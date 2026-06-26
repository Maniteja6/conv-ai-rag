# ============================================================================
# modules/etl-pipeline/lambda-etl — embedding generator
# Reads chunks, calls Bedrock Titan to embed (batched), writes vectors to S3
# (embeddings/ prefix), invokes the OpenSearch loader. Bedrock access is via
# the VPC interface endpoint (no internet egress).
# ============================================================================

resource "aws_lambda_function" "embedding_generator" {
  function_name = "${local.name}-embedding-generator"
  role          = var.execution_role_arn
  runtime       = var.runtime
  architectures = [var.architecture]
  handler       = "handler.handler"
  filename      = data.archive_file.function["embedding-generator"].output_path
  source_code_hash = data.archive_file.function["embedding-generator"].output_base64sha256
  layers        = local.layer_arns

  memory_size = var.function_config["embedding-generator"].memory_mb
  timeout     = var.function_config["embedding-generator"].timeout_sec

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(local.common_env, {
      DOCUMENT_BUCKET      = var.document_bucket_id
      EMBEDDINGS_PREFIX    = "embeddings/"
      EMBEDDING_MODEL_ID   = var.embedding_model_id
      EMBEDDING_DIMENSIONS = tostring(var.embedding_dimensions)
      BEDROCK_BATCH_SIZE   = "25"
      NEXT_FUNCTION_NAME   = aws_lambda_function.opensearch_loader.function_name
    })
  }

  # Embedding throughput can be bursty; reserve concurrency to avoid throttling
  # Bedrock while protecting other functions.
  reserved_concurrent_executions = var.environment == "prod" ? 20 : 5

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

  tags = merge(local.tags, { Name = "${local.name}-embedding-generator", Stage = "3-embed" })

  depends_on = [aws_cloudwatch_log_group.function]
}