# ============================================================================
# modules/etl-pipeline/lambda-etl — outputs
# ============================================================================

output "function_arns" {
  description = "Map of stage => Lambda ARN (for MWAA DAG / Step Functions)."
  value = {
    document-parser         = aws_lambda_function.document_parser.arn
    chunk-generator         = aws_lambda_function.chunk_generator.arn
    embedding-generator     = aws_lambda_function.embedding_generator.arn
    opensearch-index-loader = aws_lambda_function.opensearch_loader.arn
  }
}

output "function_names" {
  value = {
    document-parser         = aws_lambda_function.document_parser.function_name
    chunk-generator         = aws_lambda_function.chunk_generator.function_name
    embedding-generator     = aws_lambda_function.embedding_generator.function_name
    opensearch-index-loader = aws_lambda_function.opensearch_loader.function_name
  }
}

output "parser_function_name" {
  value = aws_lambda_function.document_parser.function_name
}