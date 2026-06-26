# ============================================================================
# modules/observability/backup — backup IAM role
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "observability/backup"
    ManagedBy   = "terraform"
  })

  create_role = var.backup_role_arn == null
  role_arn    = coalesce(var.backup_role_arn, try(aws_iam_role.backup[0].arn, null))
}

data "aws_iam_policy_document" "backup_assume" {
  count = local.create_role ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  count              = local.create_role ? 1 : 0
  name               = "${local.name}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}