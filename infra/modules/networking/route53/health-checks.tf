# ============================================================================
# modules/networking/route53 — health checks & DNS failover plumbing
# ============================================================================

resource "aws_route53_health_check" "primary" {
  count             = var.health_check_fqdn != null ? 1 : 0
  fqdn              = var.health_check_fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = merge(local.tags, { Name = "${local.name}-primary-healthcheck" })
}

# CloudWatch alarm fires when the endpoint is unhealthy.
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.health_check_fqdn != null ? 1 : 0
  alarm_name          = "${local.name}-route53-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Primary endpoint health check is failing."
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  tags = local.tags
}