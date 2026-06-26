# ============================================================================
# modules/ai-ml/sagemaker — input variables (optional custom model hosting)
# Used for self-hosted rerankers / fine-tuned models that aren't on Bedrock,
# e.g. a cross-encoder for retriever-service reranking.
# ============================================================================

variable "project" {
  type    = string
  default = "enterprise-ai-rag"
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_endpoint" {
  description = "Master switch — SageMaker hosting is optional."
  type        = bool
  default     = false
}

variable "vpc_subnet_ids" {
  description = "Private-app subnets for the endpoint ENIs."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "model_image" {
  description = "ECR image URI for the inference container (e.g. HF TEI/DJL)."
  type        = string
  default     = null
}

variable "model_data_url" {
  description = "S3 URI of model artifacts (model.tar.gz)."
  type        = string
  default     = null
}

variable "model_environment" {
  description = "Container environment variables."
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  type    = string
  default = "ml.g5.xlarge"
}

variable "initial_instance_count" {
  type    = number
  default = 1
}

variable "enable_autoscaling" {
  type    = bool
  default = true
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "model_artifacts_bucket_arn" {
  description = "S3 bucket ARN holding model artifacts (for IAM read scope)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}