# ============================================================================
# modules/observability/cloudwatch — input variables
# Central observability: SNS alerting hub, log groups, alarms, dashboards.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key (sns domain) for encrypting the SNS topic + log groups."
  type        = string
}

# --- Alerting ---------------------------------------------------------------
variable "alert_email_addresses" {
  description = "Email addresses subscribed to the alerts topic."
  type        = list(string)
  default     = []
}

variable "pagerduty_endpoint" {
  description = "PagerDuty (or Opsgenie) HTTPS integration URL for critical alerts."
  type        = string
  default     = null
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook for alert notifications (via chatbot or Lambda)."
  type        = string
  default     = null
}

# --- Resources to monitor (ARNs/identifiers from other modules) ------------
variable "eks_cluster_name" {
  type    = string
  default = null
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (for AWS/ApplicationELB metrics)."
  type        = string
  default     = null
}

variable "aurora_cluster_identifier" {
  type    = string
  default = null
}

variable "redis_replication_group_id" {
  type    = string
  default = null
}

variable "opensearch_domain_name" {
  type    = string
  default = null
}

variable "dynamodb_table_names" {
  type    = list(string)
  default = []
}

variable "etl_function_names" {
  description = "ETL Lambda names to alarm on errors/throttles."
  type        = list(string)
  default     = []
}

# --- Thresholds -------------------------------------------------------------
variable "alarm_thresholds" {
  description = "Tunable alarm thresholds."
  type = object({
    alb_5xx_count            = number
    alb_target_latency_p99   = number
    aurora_cpu_percent       = number
    aurora_connections       = number
    redis_cpu_percent        = number
    redis_memory_percent     = number
    opensearch_cluster_red   = number
    lambda_error_rate        = number
  })
  default = {
    alb_5xx_count          = 50
    alb_target_latency_p99 = 3.0
    aurora_cpu_percent     = 80
    aurora_connections     = 500
    redis_cpu_percent      = 75
    redis_memory_percent   = 80
    opensearch_cluster_red = 1
    lambda_error_rate      = 5
  }
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}