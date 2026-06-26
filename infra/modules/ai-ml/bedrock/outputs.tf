# ============================================================================
# modules/ai-ml/bedrock — outputs
# ============================================================================

output "text_model_id" {
  value = var.text_model_id
}

output "text_model_arn" {
  value = data.aws_bedrock_foundation_model.text.model_arn
}

output "embedding_model_id" {
  value = var.embedding_model_id
}

output "embedding_model_arn" {
  value = data.aws_bedrock_foundation_model.embedding.model_arn
}

output "guardrail_id" {
  description = "Guardrail ID (set in guardrails-service config / inline calls)."
  value       = try(aws_bedrock_guardrail.this[0].guardrail_id, null)
}

output "guardrail_arn" {
  value = try(aws_bedrock_guardrail.this[0].guardrail_arn, null)
}

output "guardrail_version" {
  value = try(aws_bedrock_guardrail_version.this[0].version, null)
}

output "knowledge_base_id" {
  description = "KB ID for RetrieveAndGenerate calls from agent-orchestrator."
  value       = try(aws_bedrockagent_knowledge_base.this[0].id, null)
}

output "knowledge_base_arn" {
  value = try(aws_bedrockagent_knowledge_base.this[0].arn, null)
}

output "data_source_id" {
  value = try(aws_bedrockagent_data_source.documents[0].data_source_id, null)
}

output "invocation_log_group_name" {
  value = try(aws_cloudwatch_log_group.bedrock_invocations[0].name, null)
}