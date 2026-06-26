# ============================================================================
# modules/ai-ml/sagemaker — outputs
# ============================================================================

output "endpoint_name" {
  description = "SageMaker endpoint name (set in retriever-service reranker config)."
  value       = try(aws_sagemaker_endpoint.this[0].name, null)
}

output "endpoint_arn" {
  value = try(aws_sagemaker_endpoint.this[0].arn, null)
}

output "model_name" {
  value = try(aws_sagemaker_model.this[0].name, null)
}

output "execution_role_arn" {
  value = try(aws_iam_role.execution[0].arn, null)
}