# ============================================================================
# modules/compute/alb — listeners & routing rules
# ============================================================================

# --- HTTP :80 -> redirect to HTTPS -----------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.tags
}

# --- HTTPS :443 -------------------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  # Default: enforce CloudFront origin verification on REST/UI traffic.
  # If the secret is set, anything reaching the ALB directly (bypassing
  # CloudFront/WAF) without the header is rejected.
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({ error = "Direct origin access denied" })
      status_code  = "403"
    }
  }

  tags = local.tags
}

# Extra SNI certificates.
resource "aws_lb_listener_certificate" "additional" {
  for_each        = toset(var.additional_certificate_arns)
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = each.value
}

# --- Rule: WebSocket path -> ws target group (NO origin-verify; CF can't
#           proxy WS, so these legitimately arrive direct) -------------------
resource "aws_lb_listener_rule" "websocket" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ws.arn
  }

  condition {
    path_pattern {
      values = ["/ws", "/ws/*"]
    }
  }

  tags = local.tags
}

# --- Rule: verified REST/UI traffic -> http target group -------------------
resource "aws_lb_listener_rule" "http_verified" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }

  # When an origin-verify secret is configured, require the header.
  dynamic "condition" {
    for_each = var.origin_verify_secret != null ? [1] : []
    content {
      http_header {
        http_header_name = "X-Origin-Verify"
        values           = [var.origin_verify_secret]
      }
    }
  }

  # Always also match on host/path so the rule is well-formed even without
  # the header condition.
  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = local.tags
}