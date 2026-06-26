# ============================================================================
# modules/etl-pipeline/lambda-etl — document parser
# Triggered by S3 ObjectCreated. Extracts raw text from PDF/DOCX/HTML/TXT,
# writes normalized text + metadata to S3 (parsed/ prefix), then invokes the
# chunk generator. (Direct-chain mode; MWAA can also orchestrate in batch.)
# ============================================================================

resource "aws_lambda_function" "document_parser" {
  function_name = "${local.name}-document-parser"
  role          = var.execution_role_arn
  runtime       = var.runtime
  architectures = [var.architecture]
  handler       = "handler.handler"
  filename      = data.archive_file.function["document-parser"].output_path
  source_code_hash = data.archive_file.function["document-parser"].output_base64sha256
  layers        = local.layer_arns

  memory_size = var.function_config["document-parser"].memory_mb
  timeout     = var.function_config["document-parser"].timeout_sec

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(local.common_env, {
      DOCUMENT_BUCKET    = var.document_bucket_id
      PARSED_PREFIX      = "parsed/"
      NEXT_FUNCTION_NAME = aws_lambda_function.chunk_generator.function_name
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
    mode = "Active" # X-Ray
  }

  tags = merge(local.tags, { Name = "${local.name}-document-parser", Stage = "1-parse" })

  depends_on = [aws_cloudwatch_log_group.function]
}

# --- S3 trigger: raw/ prefix -> parser -------------------------------------
resource "aws_lambda_permission" "parser_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.document_parser.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.document_bucket_arn
}

resource "aws_s3_bucket_notification" "document_upload" {
  bucket = var.document_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.document_parser.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
  }

  depends_on = [aws_lambda_permission.parser_s3]
}