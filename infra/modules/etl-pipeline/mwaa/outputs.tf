# ============================================================================
# modules/etl-pipeline/mwaa — outputs
# ============================================================================

output "environment_name" {
  value = aws_mwaa_environment.this.name
}

output "environment_arn" {
  value = aws_mwaa_environment.this.arn
}

output "webserver_url" {
  description = "Airflow UI URL (private; reach via VPN/bastion if PRIVATE_ONLY)."
  value       = aws_mwaa_environment.this.webserver_url
}

output "mwaa_security_group_id" {
  value = aws_security_group.mwaa.id
}

output "service_role_arn" {
  value = aws_mwaa_environment.this.service_role_arn
}