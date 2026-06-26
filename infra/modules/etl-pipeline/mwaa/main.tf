# ============================================================================
# modules/etl-pipeline/mwaa — security group + locals
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "etl-pipeline/mwaa"
    ManagedBy   = "terraform"
  })
}

# MWAA-managed security group (self-referencing for internal comms).
resource "aws_security_group" "mwaa" {
  name        = "${local.name}-mwaa-sg"
  description = "MWAA environment security group."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name}-mwaa-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "mwaa_self" {
  security_group_id            = aws_security_group.mwaa.id
  description                  = "Self-referencing internal traffic"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.mwaa.id
}

resource "aws_vpc_security_group_egress_rule" "mwaa_all" {
  security_group_id = aws_security_group.mwaa.id
  description       = "All egress"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}