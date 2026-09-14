# 將 ECS service inventory worker 註冊為可擴充目標
resource "aws_appautoscaling_target" "inventory_worker" {
  max_capacity       = var.inventory_worker_max_count
  min_capacity       = var.inventory_worker_desired_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.inventory_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "inventory_worker_cpu" {
  name               = "inventory-worker-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.inventory_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.inventory_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.inventory_worker.service_namespace

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
