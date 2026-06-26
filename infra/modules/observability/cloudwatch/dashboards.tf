# ============================================================================
# modules/observability/cloudwatch — platform dashboard
# A single operational dashboard; the richer Grafana dashboards live in
# observability/grafana (repo root) backed by the CloudWatch datasource.
# ============================================================================

resource "aws_cloudwatch_dashboard" "platform" {
  dashboard_name = "${local.name}-platform"

  dashboard_body = jsonencode({
    widgets = concat(
      # --- ALB row ---
      var.alb_arn_suffix != null ? [{
        type   = "metric"
        x      = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB Requests & 5xx"
          region = var.region
          view   = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
          ]
        }
      }] : [],

      # --- Latency ---
      var.alb_arn_suffix != null ? [{
        type   = "metric"
        x      = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Target Latency (p50/p99)"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50" }],
            ["...", { stat = "p99" }],
          ]
        }
      }] : [],

      # --- Aurora ---
      var.aurora_cluster_identifier != null ? [{
        type   = "metric"
        x      = 0, y = 6, width = 8, height = 6
        properties = {
          title  = "Aurora CPU & Connections"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.aurora_cluster_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_identifier, { yAxis = "right" }],
          ]
        }
      }] : [],

      # --- Custom: RAG metrics ---
      [{
        type   = "metric"
        x      = 8, y = 6, width = 8, height = 6
        properties = {
          title  = "RAG: Errors & Guardrail Blocks"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["${var.project}/${var.environment}", "ApplicationErrors", { stat = "Sum" }],
            ["${var.project}/${var.environment}", "GuardrailBlocks", { stat = "Sum" }],
          ]
        }
      }]
    )
  })
}