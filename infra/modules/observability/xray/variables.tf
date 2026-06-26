# ============================================================================
# modules/observability/xray — input variables
# Distributed tracing across the microservice call graph (chat-gateway ->
# query-router -> agent-orchestrator -> retriever -> Bedrock).
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "sampling_rate" {
  description = "Fraction of requests traced after the reservoir (0.0-1.0)."
  type        = number
  default     = 0.1
}

variable "reservoir_size" {
  description = "Traces per second sampled before applying the rate."
  type        = number
  default     = 2
}

variable "high_value_paths" {
  description = "URL paths always traced at higher rate (e.g. /api/chat)."
  type        = list(string)
  default     = ["/api/chat", "/api/v1/chat"]
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}