# ============================================================================
# modules/compute/eks-node-groups — system managed node group
# Hosts core controllers (CoreDNS, Karpenter, ALB controller, etc.) on a
# stable, always-on footprint. Application pods scale on Karpenter nodes.
# ============================================================================

resource "aws_eks_node_group" "system" {
  cluster_name    = var.cluster_name
  node_group_name = "${local.name}-system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_app_subnet_ids
  capacity_type   = var.system_node_group.capacity_type
  instance_types  = var.system_node_group.instance_types

  scaling_config {
    min_size     = var.system_node_group.min_size
    max_size     = var.system_node_group.max_size
    desired_size = var.system_node_group.desired_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.system.id
    version = aws_launch_template.system.latest_version
  }

  # Reserve these nodes for system/critical workloads.
  labels = {
    "node.kubernetes.io/role" = "system"
    "workload"                = "system"
  }

  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # let autoscaler own this
  }

  tags = merge(local.tags, {
    Name                     = "${local.name}-system"
    "karpenter.sh/discovery" = var.cluster_name
  })

  depends_on = [aws_iam_role_policy_attachment.node]
}