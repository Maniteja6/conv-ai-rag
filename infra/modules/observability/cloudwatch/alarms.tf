# ============================================================================
# modules/observability/cloudwatch — alarms
# Each alarm publishes to the alerts topic (and critical for sev-1).
# All alarms are conditional on the relevant resource identifier being set,
# so the module is safe to apply before every dependency exists.
# ============================================================================

# --- ALB: 5xx + latency -----------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.alb_arn_suffix != null ? 1 : 0
  alarm_name          = "${local.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_thresholds.alb_5xx_count
  alarm_description   = "ALB returning elevated 5xx errors."
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  count               = var.alb_arn_suffix != null ? 1 : 0
  alarm_name          = "${local.name}-alb-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.alarm_thresholds.alb_target_latency_p99
  alarm_description   = "p99 target latency above threshold."
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Aurora -----------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  count               = var.aurora_cluster_identifier != null ? 1 : 0
  alarm_name          = "${local.name}-aurora-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.alarm_thresholds.aurora_cpu_percent
  alarm_description   = "Aurora CPU high."
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections" {
  count               = var.aurora_cluster_identifier != null ? 1 : 0
  alarm_name          = "${local.name}-aurora-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.alarm_thresholds.aurora_connections
  alarm_description   = "Aurora connection count high — check RDS Proxy pooling."
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Redis ------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  count               = var.redis_replication_group_id != null ? 1 : 0
  alarm_name          = "${local.name}-redis-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = var.alarm_thresholds.redis_cpu_percent
  alarm_description   = "Redis engine CPU high."
  dimensions          = { ReplicationGroupId = var.redis_replication_group_id }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  count               = var.redis_replication_group_id != null ? 1 : 0
  alarm_name          = "${local.name}-redis-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = var.alarm_thresholds.redis_memory_percent
  alarm_description   = "Redis memory usage high — eviction risk."
  dimensions          = { ReplicationGroupId = var.redis_replication_group_id }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- OpenSearch cluster status ---------------------------------------------
resource "aws_cloudwatch_metric_alarm" "opensearch_red" {
  count               = var.opensearch_domain_name != null ? 1 : 0
  alarm_name          = "${local.name}-opensearch-red"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.alarm_thresholds.opensearch_cluster_red
  alarm_description   = "OpenSearch cluster RED — index unavailable."
  dimensions = {
    DomainName = var.opensearch_domain_name
    ClientId   = var.account_id
  }
  alarm_actions = [aws_sns_topic.critical.arn, aws_sns_topic.alerts.arn]
  tags          = local.tags
}

# --- ETL Lambda errors ------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each            = toset(var.etl_function_names)
  alarm_name          = "${each.value}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_thresholds.lambda_error_rate
  alarm_description   = "ETL function ${each.value} erroring."
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = each.value }
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}

# --- Application error rate (from log metric filter) -----------------------
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${local.name}-app-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApplicationErrors"
  namespace           = "${var.project}/${var.environment}"
  period              = 60
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "Elevated application ERROR log volume."
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.tags
}