# ============================================================================
# modules/data-layer/dynamodb — tables
# ============================================================================

# --- Sessions table ---------------------------------------------------------
# PK: session_id | TTL on expires_at | GSI on user_id for "my sessions".
resource "aws_dynamodb_table" "sessions" {
  name         = "${local.name}-sessions"
  billing_mode = var.billing_mode
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }
  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "user-sessions-index"
    hash_key        = "user_id"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  stream_enabled   = var.enable_global_tables
  stream_view_type = var.enable_global_tables ? "NEW_AND_OLD_IMAGES" : null

  deletion_protection_enabled = var.deletion_protection

  dynamic "replica" {
    for_each = var.enable_global_tables ? var.replica_regions : []
    content {
      region_name = replica.value
      kms_key_arn = var.kms_key_arn # NOTE: must be a key in the replica region
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-sessions" })
}

# --- Chat history table -----------------------------------------------------
# PK: conversation_id | SK: message_ts (sortable message log).
resource "aws_dynamodb_table" "chat_history" {
  name         = "${local.name}-chat-history"
  billing_mode = var.billing_mode
  hash_key     = "conversation_id"
  range_key    = "message_ts"

  attribute {
    name = "conversation_id"
    type = "S"
  }
  attribute {
    name = "message_ts"
    type = "N"
  }
  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "user-conversations-index"
    hash_key        = "user_id"
    range_key       = "message_ts"
    projection_type = "KEYS_ONLY"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  stream_enabled   = var.enable_global_tables
  stream_view_type = var.enable_global_tables ? "NEW_AND_OLD_IMAGES" : null

  deletion_protection_enabled = var.deletion_protection

  dynamic "replica" {
    for_each = var.enable_global_tables ? var.replica_regions : []
    content {
      region_name = replica.value
      kms_key_arn = var.kms_key_arn
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-chat-history" })
}