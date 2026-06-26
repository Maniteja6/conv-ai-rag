# ============================================================================
# modules/data-layer/opensearch — domain
# ============================================================================

resource "aws_opensearch_domain" "this" {
  domain_name    = local.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }

    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count   = var.dedicated_master_enabled ? var.dedicated_master_count : null
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
  }

  vpc_options {
    subnet_ids         = slice(var.vpc_subnet_ids, 0, var.availability_zone_count)
    security_group_ids = [var.security_group_id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  # Fine-grained access control with an internal master user (if secret given).
  dynamic "advanced_security_options" {
    for_each = var.master_user_secret_arn != null ? [1] : []
    content {
      enabled                        = true
      internal_user_database_enabled = true
      master_user_options {
        master_user_name     = jsondecode(data.aws_secretsmanager_secret_version.master[0].secret_string)["username"]
        master_user_password = jsondecode(data.aws_secretsmanager_secret_version.master[0].secret_string)["password"]
      }
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["index"].arn
    log_type                 = "INDEX_SLOW_LOGS"
  }
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["search"].arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["es_app"].arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  auto_tune_options {
    desired_state = "ENABLED"
  }

  tags = merge(local.tags, { Name = local.domain_name })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

# --- Slow-log groups --------------------------------------------------------
resource "aws_cloudwatch_log_group" "opensearch" {
  for_each = {
    index  = "index-slow"
    search = "search-slow"
    es_app = "application"
  }
  name              = "/aws/opensearch/${local.domain_name}/${each.value}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}

# Resource-based policy so OpenSearch can write to the log groups.
resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${local.name}-opensearch-logs"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "es.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream", "logs:PutLogEventsBatch"]
      Resource  = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/opensearch/${local.domain_name}/*"
    }]
  })
}