# ============================================================================
# modules/edge-security/shield-advanced — resource protections
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "edge-security/shield-advanced"
    ManagedBy   = "terraform"
  })
}

# --- Protect each supplied resource ----------------------------------------
resource "aws_shield_protection" "this" {
  for_each = var.protected_resources

  name         = "${local.name}-${each.key}"
  resource_arn = each.value
  tags         = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

# --- SRT (Shield Response Team) access -------------------------------------
resource "aws_shield_drt_access_role_arn_association" "this" {
  count    = var.enable_drt_access && var.drt_role_arn != null ? 1 : 0
  role_arn = var.drt_role_arn
}

# --- Proactive engagement & emergency contacts -----------------------------
resource "aws_shield_proactive_engagement" "this" {
  count   = var.enable_proactive_engagement ? 1 : 0
  enabled = true

  dynamic "emergency_contact" {
    for_each = var.emergency_contacts
    content {
      email_address = emergency_contact.value.email_address
      phone_number  = emergency_contact.value.phone_number
      contact_notes = emergency_contact.value.contact_notes
    }
  }
}

# --- Application-layer automatic response (for CloudFront/ALB) --------------
resource "aws_shield_application_layer_automatic_response" "this" {
  for_each = {
    for k, v in var.protected_resources : k => v
    if can(regex("cloudfront|loadbalancer", v))
  }

  resource_arn = each.value
  action       = "BLOCK"

  depends_on = [aws_shield_protection.this]
}