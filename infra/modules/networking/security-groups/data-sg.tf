# ============================================================================
# Data-tier security groups: Aurora PostgreSQL, OpenSearch, ElastiCache Redis
# Each accepts traffic ONLY from the EKS node SG on its service port.
# ============================================================================

# --- Aurora PostgreSQL ------------------------------------------------------
resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora-sg"
  description = "Aurora PostgreSQL: 5432 from EKS nodes only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name}-aurora-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_eks" {
  security_group_id            = aws_security_group.aurora.id
  description                  = "PostgreSQL from EKS"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "aurora_egress" {
  security_group_id = aws_security_group.aurora.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# --- OpenSearch -------------------------------------------------------------
resource "aws_security_group" "opensearch" {
  name        = "${local.name}-opensearch-sg"
  description = "OpenSearch: 443 from EKS nodes only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name}-opensearch-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "opensearch_from_eks" {
  security_group_id            = aws_security_group.opensearch.id
  description                  = "HTTPS from EKS"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "opensearch_egress" {
  security_group_id = aws_security_group.opensearch.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# --- ElastiCache Redis ------------------------------------------------------
resource "aws_security_group" "redis" {
  name        = "${local.name}-redis-sg"
  description = "ElastiCache Redis: 6379 from EKS nodes only."
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name}-redis-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis from EKS"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "redis_egress" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}