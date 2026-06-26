# ============================================================================
# modules/ai-ml/bedrock — Knowledge Base (managed RAG)
# Wires: S3 documents -> Titan embeddings -> OpenSearch vector index.
# This is the managed alternative to the hand-rolled ETL pipeline (Glue/MWAA/
# Lambda). Both can coexist; the KB is simplest for native RetrieveAndGenerate.
# ============================================================================

# --- KB execution role ------------------------------------------------------
data "aws_iam_policy_document" "kb_assume" {
  count = local.create_kb_role ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_iam_role" "kb" {
  count              = local.create_kb_role ? 1 : 0
  name               = "${local.name}-bedrock-kb"
  assume_role_policy = data.aws_iam_policy_document.kb_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "kb" {
  count = local.create_kb_role ? 1 : 0

  statement {
    sid       = "InvokeEmbeddingModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:${var.region}::foundation-model/${var.embedding_model_id}"]
  }

  statement {
    sid       = "ReadDocuments"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = compact([var.document_bucket_arn, "${var.document_bucket_arn}/*"])
  }

  dynamic "statement" {
    for_each = var.opensearch_collection_arn != null ? [1] : []
    content {
      sid       = "OpenSearchAccess"
      effect    = "Allow"
      actions   = ["aoss:APIAccessAll", "es:ESHttp*"]
      resources = [var.opensearch_collection_arn, "${var.opensearch_collection_arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "kb" {
  count  = local.create_kb_role ? 1 : 0
  name   = "${local.name}-bedrock-kb"
  role   = aws_iam_role.kb[0].id
  policy = data.aws_iam_policy_document.kb[0].json
}

# --- Knowledge Base ---------------------------------------------------------
resource "aws_bedrockagent_knowledge_base" "this" {
  count    = var.enable_knowledge_base ? 1 : 0
  name     = "${local.name}-kb"
  role_arn = local.kb_role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/${var.embedding_model_id}"

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions = var.embedding_dimensions
        }
      }
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = var.opensearch_collection_arn
      vector_index_name = var.vector_index_name
      field_mapping {
        vector_field   = "vector"
        text_field     = "text"
        metadata_field = "metadata"
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-kb" })

  depends_on = [aws_iam_role_policy.kb]
}

# --- Data source: the S3 document bucket -----------------------------------
resource "aws_bedrockagent_data_source" "documents" {
  count             = var.enable_knowledge_base && var.document_bucket_arn != null ? 1 : 0
  knowledge_base_id = aws_bedrockagent_knowledge_base.this[0].id
  name              = "${local.name}-s3-documents"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.document_bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 512
        overlap_percentage = 20
      }
    }
  }

  data_deletion_policy = "RETAIN"
}