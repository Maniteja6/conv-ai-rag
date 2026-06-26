# ============================================================================
# modules/ai-ml/bedrock — locals
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "ai-ml/bedrock"
    ManagedBy   = "terraform"
  })

  create_kb_role = var.enable_knowledge_base && var.kb_role_arn == null
  kb_role_arn    = var.enable_knowledge_base ? coalesce(var.kb_role_arn, try(aws_iam_role.kb[0].arn, null)) : null
}