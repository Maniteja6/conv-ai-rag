# ============================================================================
# modules/etl-pipeline/lambda-etl — chunk generator
# Reads parsed text, applies chunking strategy (fixed/semantic/recursive),
# writes chunks to S3 (chunks/ prefix), invokes the embedding generator.
# ============================================================================

resource "aws_lambda_function" "chunk_generator" {
  function_name = "${local.name}-chunk-generator"
  role          = var.execution_role_arn
  runtime       = var.runtime
  architectures = [var.architecture]
  handler       = "handler.handler"
  filename      = data.archive_file.function["chunk-generator"].output_path
  source_code_hash = data.archive_file.function["chunk-generator"].output_base64sha256
  layers        = local.layer_arns

  memory_size = var.function_config["chunk-generator"].memory_mb
  timeout     = var.function_config["chunk-generator"].timeout_sec

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(local.common_env, {
      DOCUMENT_BUCKET    = var.document_bucket_id
      CHUNKS_PREFIX      = "chunks/"
      CHUNK_SIZE_TOKENS  = "512"
      CHUNK_OVERLAP      = "64"
      CHUNKING_STRATEGY  = "recursive"
      NEXT_FUNCTION_NAME = aws_lambda_function.embedding_generator.function_name
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

  tags = merge(local.tags, { Name = "${local.name}-chunk-generator", Stage = "2-chunk" })

  depends_on = [aws_cloudwatch_log_group.function]
}