# ============================================================================
# modules/ai-ml/sagemaker — endpoint config, endpoint, autoscaling
# ============================================================================

resource "aws_sagemaker_endpoint_configuration" "this" {
  count = local.enabled ? 1 : 0
  name  = "${local.name}-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.this[0].name
    initial_instance_count = var.initial_instance_count
    instance_type          = var.instance_type
    initial_variant_weight = 1.0
  }

  kms_key_arn = var.kms_key_arn

  tags = merge(local.tags, { Name = "${local.name}-endpoint-config" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sagemaker_endpoint" "this" {
  count                = local.enabled ? 1 : 0
  name                 = "${local.name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.this[0].name
  tags                 = merge(local.tags, { Name = "${local.name}-endpoint" })
}

# --- Autoscaling ------------------------------------------------------------
resource "aws_appautoscaling_target" "sagemaker" {
  count              = local.enabled && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.this[0].name}/variant/primary"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

resource "aws_appautoscaling_policy" "sagemaker" {
  count              = local.enabled && var.enable_autoscaling ? 1 : 0
  name               = "${local.name}-sagemaker-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
    target_value       = 750  # invocations per instance per minute
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}