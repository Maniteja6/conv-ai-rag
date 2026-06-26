# ============================================================================
# modules/security/iam — AWS service-linked / service-assumed roles
# Roles assumed by AWS services (Lambda, Glue, MWAA, etc.), not by pods.
# ============================================================================

# --- Lambda ETL execution role ---------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_etl" {
  name               = "${local.name}-lambda-etl"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = merge(local.tags, { Name = "${local.name}-lambda-etl" })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_etl.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock" {
  role       = aws_iam_role.lambda_etl.name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  count      = var.document_bucket_arn != null ? 1 : 0
  role       = aws_iam_role.lambda_etl.name
  policy_arn = aws_iam_policy.s3_documents[0].arn
}

resource "aws_iam_role_policy_attachment" "lambda_opensearch" {
  count      = var.opensearch_domain_arn != null ? 1 : 0
  role       = aws_iam_role.lambda_etl.name
  policy_arn = aws_iam_policy.opensearch_access[0].arn
}

# --- Glue crawler/job role --------------------------------------------------
data "aws_iam_policy_document" "glue_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue" {
  name               = "${local.name}-glue"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
  tags               = merge(local.tags, { Name = "${local.name}-glue" })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  count      = var.document_bucket_arn != null ? 1 : 0
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.s3_documents[0].arn
}

# --- MWAA (Managed Airflow) execution role ---------------------------------
data "aws_iam_policy_document" "mwaa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "airflow.amazonaws.com",
        "airflow-env.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "mwaa" {
  name               = "${local.name}-mwaa"
  assume_role_policy = data.aws_iam_policy_document.mwaa_assume.json
  tags               = merge(local.tags, { Name = "${local.name}-mwaa" })
}

data "aws_iam_policy_document" "mwaa_exec" {
  statement {
    sid       = "AirflowMetrics"
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:${var.region}:${var.account_id}:environment/${local.name}-*"]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream", "logs:CreateLogGroup", "logs:PutLogEvents",
      "logs:GetLogEvents", "logs:GetLogRecord", "logs:GetLogGroupFields",
      "logs:GetQueryResults", "logs:DescribeLogGroups",
    ]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:airflow-${local.name}-*"]
  }

  statement {
    sid       = "Metrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mwaa_exec" {
  name   = "${local.name}-mwaa-exec"
  role   = aws_iam_role.mwaa.id
  policy = data.aws_iam_policy_document.mwaa_exec.json
}

resource "aws_iam_role_policy_attachment" "mwaa_bedrock" {
  role       = aws_iam_role.mwaa.name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

resource "aws_iam_role_policy_attachment" "mwaa_s3" {
  count      = var.document_bucket_arn != null ? 1 : 0
  role       = aws_iam_role.mwaa.name
  policy_arn = aws_iam_policy.s3_documents[0].arn
}