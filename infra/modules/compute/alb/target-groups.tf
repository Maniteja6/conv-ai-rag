# ============================================================================
# modules/compute/alb — target groups
# Two groups:
#   * http : REST/UI traffic (chat-gateway HTTP, api-service)
#   * ws   : WebSocket traffic (chat-gateway /ws) — sticky, long timeout
# Targets are registered by the AWS Load Balancer Controller via TargetGroup
# Bindings, so target_type = "ip" and we don't attach instances here.
# ============================================================================

resource "aws_lb_target_group" "http" {
  name        = "${local.name}-http"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  deregistration_delay = 30

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  tags = merge(local.tags, { Name = "${local.name}-http-tg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_lb_target_group" "ws" {
  name        = "${local.name}-ws"
  port        = 8081
  protocol    = "HTTP" # WS upgrades over HTTP listener
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  # WebSocket connections are long-lived; keep clients pinned + slow drain.
  deregistration_delay = 120

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = true
  }

  tags = merge(local.tags, { Name = "${local.name}-ws-tg" })

  lifecycle { create_before_destroy = true }
}