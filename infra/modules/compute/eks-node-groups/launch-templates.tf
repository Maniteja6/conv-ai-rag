# ============================================================================
# modules/compute/eks-node-groups — launch template (encrypted EBS, IMDSv2)
# ============================================================================

resource "aws_launch_template" "system" {
  name_prefix = "${local.name}-system-"
  description = "System node group launch template (encrypted EBS, IMDSv2)."

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.system_node_group.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  # Enforce IMDSv2 (CIS / Checkov requirement).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [
    var.eks_nodes_security_group_id,
    var.cluster_security_group_id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name = "${local.name}-system-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.tags, { Name = "${local.name}-system-vol" })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}