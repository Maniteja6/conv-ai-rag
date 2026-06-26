# ============================================================================
# modules/data-layer/dynamodb — outputs
# ============================================================================

output "sessions_table_name" {
  value = aws_dynamodb_table.sessions.name
}

output "sessions_table_arn" {
  value = aws_dynamodb_table.sessions.arn
}

output "chat_history_table_name" {
  value = aws_dynamodb_table.chat_history.name
}

output "chat_history_table_arn" {
  value = aws_dynamodb_table.chat_history.arn
}

output "all_table_arns" {
  description = "Feeds modules/security/iam dynamodb_table_arns."
  value = [
    aws_dynamodb_table.sessions.arn,
    aws_dynamodb_table.chat_history.arn,
  ]
}