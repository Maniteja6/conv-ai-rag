# ============================================================================
# modules/etl-pipeline/mwaa — the Airflow environment
# ============================================================================

resource "aws_mwaa_environment" "this" {
  name              = "${local.name}-airflow"
  airflow_version   = var.airflow_version
  environment_class = var.environment_class
  execution_role_arn = var.mwaa_role_arn
  kms_key           = var.kms_key_arn

  source_bucket_arn    = var.source_bucket_arn
  dag_s3_path          = var.dags_s3_path
  requirements_s3_path = var.requirements_s3_path

  min_workers = var.min_workers
  max_workers = var.max_workers

  webserver_access_mode = var.webserver_access_mode

  network_configuration {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = concat([aws_security_group.mwaa.id], var.source_security_group_ids)
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "WARNING"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  # Airflow config overrides — pass ETL Lambda names to DAGs via env.
  airflow_configuration_options = {
    "core.default_task_retries" = "2"
    "core.parallelism"          = "32"
    "webserver.dag_default_view" = "graph"
  }

  tags = merge(local.tags, { Name = "${local.name}-airflow" })
}