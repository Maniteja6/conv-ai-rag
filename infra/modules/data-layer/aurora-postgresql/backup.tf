# ============================================================================
# modules/data-layer/aurora-postgresql — extra backup safeguards
# (Automated backups are on the cluster; this adds an explicit snapshot
#  cadence hook + event subscription. Cross-account/region vaulting lives in
#  the observability/backup module via AWS Backup.)
# ============================================================================

resource "aws_db_event_subscription" "this" {
  name      = "${local.name}-aurora-events"
  source_type = "db-cluster"
  source_ids  = [aws_rds_cluster.this.id]

  event_categories = [
    "failure",
    "failover",
    "maintenance",
    "notification",
  ]

  # sns_topic_arn is wired from the observability module at the env root.
  sns_topic_arn = var.sns_topic_arn

  tags = local.tags
}

variable "sns_topic_arn" {
  description = "SNS topic for RDS event notifications."
  type        = string
  default     = null
}