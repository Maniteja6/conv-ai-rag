# ============================================================================
# Public Application Load Balancer security group
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Public ALB: allow inbound HTTP/HTTPS from the internet."
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-alb-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet (redirected to HTTPS at listener)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_eks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to EKS nodes"
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  referenced_security_group_id = aws_security_group.eks_nodes.id
}