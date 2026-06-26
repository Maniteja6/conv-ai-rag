# ============================================================================
# modules/etl-pipeline/lambda-etl — shared locals, layers, packaging
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "etl-pipeline/lambda-etl"
    ManagedBy   = "terraform"
  })

  functions = ["document-parser", "chunk-generator", "embedding-generator", "opensearch-index-loader"]

  # Common environment for all functions.
  common_env = {
    ENVIRONMENT          = var.environment
    PROJECT              = var.project
    LOG_LEVEL            = var.environment == "prod" ? "INFO" : "DEBUG"
    POWERTOOLS_SERVICE_NAME = "${local.name}-etl"
  }
}

# --- Package each function from data-pipeline/lambda-functions/<name>/ ------
data "archive_file" "function" {
  for_each    = toset(local.functions)
  type        = "zip"
  source_dir  = "${var.source_dir}/${each.value}"
  output_path = "${path.module}/.build/${each.value}.zip"
  excludes    = ["tests", "tests/*", "__pycache__", "*.pyc", "requirements.txt"]
}

# --- Shared dependencies layer (boto3 extras, opensearch-py, etc.) ---------
# Built out-of-band by scripts/bootstrap.sh into .build/layer.zip, or supply
# a prebuilt layer ARN. Here we package from a known path if present.
data "archive_file" "deps_layer" {
  count       = fileexists("${path.module}/.build/layer/python") ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/.build/layer"
  output_path = "${path.module}/.build/layer.zip"
}

resource "aws_lambda_layer_version" "deps" {
  count                    = length(data.archive_file.deps_layer) > 0 ? 1 : 0
  layer_name               = "${local.name}-etl-deps"
  filename                 = data.archive_file.deps_layer[0].output_path
  source_code_hash         = data.archive_file.deps_layer[0].output_base64sha256
  compatible_runtimes      = [var.runtime]
  compatible_architectures = [var.architecture]
}

locals {
  layer_arns = length(aws_lambda_layer_version.deps) > 0 ? [aws_lambda_layer_version.deps[0].arn] : []
}

# --- Log groups (one per function) -----------------------------------------
resource "aws_cloudwatch_log_group" "function" {
  for_each          = toset(local.functions)
  name              = "/aws/lambda/${local.name}-${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.tags
}