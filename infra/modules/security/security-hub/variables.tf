# ============================================================================
# modules/security/security-hub — input variables
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_cis_standard" {
  description = "Enable CIS AWS Foundations Benchmark."
  type        = bool
  default     = true
}

variable "enable_aws_foundational_standard" {
  description = "Enable AWS Foundational Security Best Practices."
  type        = bool
  default     = true
}

variable "enable_pci_standard" {
  description = "Enable PCI DSS standard (set true only if in scope)."
  type        = bool
  default     = false
}

variable "auto_enable_controls" {
  description = "Auto-enable new controls as AWS adds them."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}