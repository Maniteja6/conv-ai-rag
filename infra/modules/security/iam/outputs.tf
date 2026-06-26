# ============================================================================
# modules/security/iam — outputs
# ============================================================================

output "irsa_role_arns" {
  description = "Map of service logical name => IRSA role ARN (annotate K8s SAs with these)."
  value       = { for k, v in aws_iam_role.irsa : k => v.arn }
}

output "lambda_etl_role_arn" {
  description = "Execution role ARN for ETL Lambda functions."
  value       = aws_iam_role.lambda_etl.arn
}

output "glue_role_arn" {
  description = "Glue crawler/job role ARN."
  value       = aws_iam_role.glue.arn
}

output "mwaa_role_arn" {
  description = "MWAA execution role ARN."
  value       = aws_iam_role.mwaa.arn
}

output "managed_policy_arns" {
  description = "Reusable managed policy ARNs."
  value = {
    bedrock_invoke = aws_iam_policy.bedrock_invoke.arn
    observability  = aws_iam_policy.observability.arn
    s3_documents   = try(aws_iam_policy.s3_documents[0].arn, null)
    opensearch     = try(aws_iam_policy.opensearch_access[0].arn, null)
    dynamodb       = try(aws_iam_policy.dynamodb_access[0].arn, null)
    secrets_read   = try(aws_iam_policy.secrets_read[0].arn, null)
  }
}