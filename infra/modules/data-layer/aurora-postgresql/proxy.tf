# ============================================================================
# modules/data-layer/aurora-postgresql — RDS Proxy (connection pooling)
# Critical for EKS: hundreds of pods would otherwise exhaust DB connections.
# ============================================================================

locals {
  create_proxy_role = var.enable_rds_proxy && var.proxy_role_arn == null
  proxy_secret_arn  = var.manage_master_password ? aws_rds_cluster.this.master_user_secret[0].secret_arn : var.master_password_secret_arn
}

# --- Proxy IAM role (if not supplied) --------------------------------------
data "aws_iam_policy_document" "proxy_assume" {
  count = local.create_proxy_role ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "proxy" {
  count              = local.create_proxy_role ? 1 : 0
  name               = "${local.name}-rds-proxy"
  assume_role_policy = data.aws_iam_policy_document.proxy_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "proxy_secrets" {
  count = local.create_proxy_role ? 1 : 0

  statement {
    sid       = "GetSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.proxy_secret_arn]
  }
  statement {
    sid       = "DecryptSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [coalesce(var.secrets_kms_key_arn, var.kms_key_arn)]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

data "aws_region" "current" {}

resource "aws_iam_role_policy" "proxy_secrets" {
  count  = local.create_proxy_role ? 1 : 0
  name   = "${local.name}-rds-proxy-secrets"
  role   = aws_iam_role.proxy[0].id
  policy = data.aws_iam_policy_document.proxy_secrets[0].json
}

# --- The proxy --------------------------------------------------------------
resource "aws_db_proxy" "this" {
  count                  = var.enable_rds_proxy ? 1 : 0
  name                   = "${local.name}-aurora-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = coalesce(var.proxy_role_arn, try(aws_iam_role.proxy[0].arn, null))
  vpc_subnet_ids         = data.aws_db_subnet_group.this.subnet_ids
  vpc_security_group_ids = [var.security_group_id]
  require_tls            = true
  idle_client_timeout    = 1800
  debug_logging          = false

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = local.proxy_secret_arn
  }

  tags = merge(local.tags, { Name = "${local.name}-aurora-proxy" })
}

data "aws_db_subnet_group" "this" {
  name = var.db_subnet_group_name
}

resource "aws_db_proxy_default_target_group" "this" {
  count         = var.enable_rds_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  count                 = var.enable_rds_proxy ? 1 : 0
  db_proxy_name         = aws_db_proxy.this[0].name
  target_group_name     = aws_db_proxy_default_target_group.this[0].name
  db_cluster_identifier = aws_rds_cluster.this.id
}