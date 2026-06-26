# ============================================================================
# modules/ai-ml/bedrock — Bedrock Guardrails
# Applied by guardrails-service (ApplyGuardrail) and optionally inline on
# InvokeModel / RetrieveAndGenerate calls.
# ============================================================================

resource "aws_bedrock_guardrail" "this" {
  count = var.enable_guardrails ? 1 : 0

  name                      = "${local.name}-guardrail"
  description               = "Content, topic, PII, and word filters for ${var.project}."
  blocked_input_messaging   = var.guardrail_blocked_input_message
  blocked_outputs_messaging = var.guardrail_blocked_output_message
  kms_key_arn               = var.kms_key_arn

  # --- Harmful content filters (tunable strength per category) ---
  content_policy_config {
    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE" # prompt-attack only meaningful on input
    }
  }

  # --- Denied topics ---
  dynamic "topic_policy_config" {
    for_each = length(var.denied_topics) > 0 ? [1] : []
    content {
      dynamic "topics_config" {
        for_each = var.denied_topics
        content {
          name       = topics_config.key
          definition = topics_config.value
          type       = "DENY"
        }
      }
    }
  }

  # --- Sensitive information (PII) ---
  sensitive_information_policy_config {
    dynamic "pii_entities_config" {
      for_each = toset(var.pii_entities_to_anonymize)
      content {
        type   = pii_entities_config.value
        action = "ANONYMIZE"
      }
    }
  }

  # --- Word filters ---
  dynamic "word_policy_config" {
    for_each = length(var.word_filters) > 0 ? [1] : []
    content {
      dynamic "words_config" {
        for_each = toset(var.word_filters)
        content {
          text = words_config.value
        }
      }
      managed_word_lists_config {
        type = "PROFANITY"
      }
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-guardrail" })
}

# Publish a stable version for production reference.
resource "aws_bedrock_guardrail_version" "this" {
  count         = var.enable_guardrails ? 1 : 0
  guardrail_arn = aws_bedrock_guardrail.this[0].guardrail_arn
  description   = "Published version for ${var.environment}."

  lifecycle {
    create_before_destroy = true
  }
}