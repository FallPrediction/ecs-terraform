# 將 ECS service general worker 註冊為可擴充目標
resource "aws_appautoscaling_target" "general_worker" {
  max_capacity       = var.general_worker_max_count
  min_capacity       = var.general_worker_desired_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.general_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "general_worker_cpu" {
  name               = "general-worker-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.general_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.general_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.general_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      # See https://docs.aws.amazon.com/autoscaling/plans/APIReference/API_PredefinedScalingMetricSpecification.html
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 30
  }
}
