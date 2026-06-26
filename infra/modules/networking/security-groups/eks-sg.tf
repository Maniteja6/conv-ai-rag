# ============================================================================
# EKS worker node / pod security group
# ============================================================================

resource "aws_security_group" "eks_nodes" {
  name        = "${local.name}-eks-nodes-sg"
  description = "EKS worker nodes: ALB ingress, intra-node, egress to data + endpoints."
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-eks-nodes-sg"
  })

  lifecycle { create_before_destroy = true }
}

# Ingress: from the ALB
resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Traffic from public ALB"
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  referenced_security_group_id = aws_security_group.alb.id
}

# Ingress: node-to-node (pod networking, kubelet, coredns, etc.)
resource "aws_vpc_security_group_ingress_rule" "eks_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Intra-node / pod-to-pod"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# Egress: allow all (locked down further by NACL + endpoint SGs)
resource "aws_vpc_security_group_egress_rule" "eks_all" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "All egress"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}