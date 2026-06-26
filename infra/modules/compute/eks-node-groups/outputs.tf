# ============================================================================
# modules/compute/eks-node-groups — outputs
# ============================================================================

output "node_role_arn" {
  description = "Shared worker node IAM role ARN (referenced by Karpenter EC2NodeClass)."
  value       = aws_iam_role.node.arn
}

output "node_instance_profile_name" {
  value = aws_iam_instance_profile.node.name
}

output "system_node_group_arn" {
  value = aws_eks_node_group.system.arn
}

output "karpenter_controller_role_arn" {
  description = "IRSA role ARN for the Karpenter controller (set in its Helm values)."
  value       = try(aws_iam_role.karpenter_controller[0].arn, null)
}

output "karpenter_interruption_queue_name" {
  value = try(aws_sqs_queue.karpenter_interruption[0].name, null)
}