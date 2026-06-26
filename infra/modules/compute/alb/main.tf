# ============================================================================
# modules/compute/alb — Application Load Balancer
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "compute/alb"
    ManagedBy   = "terraform"
  })
}

resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true
  enable_http2               = true
  desync_mitigation_mode     = "defensive"

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "alb/${local.name}"
      enabled = true
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-alb" })
}