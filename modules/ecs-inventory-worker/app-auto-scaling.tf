# 將 ECS service inventory worker 註冊為可擴充目標
resource "aws_appautoscaling_target" "inventory_worker" {
  max_capacity       = var.inventory_worker_max_count
  min_capacity       = 0
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.inventory_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "inventory_worker_queue_inventory_target_tracking" {
  name               = "inventory-worker-queue-inventory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.inventory_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.inventory_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.inventory_worker.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metrics {
        label = "Get the queue size (the number of messages waiting to be processed)"
        id    = "m1"

        metric_stat {
          metric {
            metric_name = "redis_key_size"
            namespace   = "ElastiCache/Prometheus"

            dimensions {
              name  = "job"
              value = "redis_exporter"
            }
            dimensions {
              name  = "db"
              value = "db0"
            }
            dimensions {
              name  = "key"
              value = "laravel-database-queues:inventory"
            }
          }

          stat = "Sum"
        }

        return_data = false
      }

      metrics {
        label = "Get the running task count (matching the period to that of the m1)"
        id    = "m2"

        metric_stat {
          metric {
            metric_name = "RunningTaskCount"
            namespace   = "ECS/ContainerInsights"

            dimensions {
              name  = "ServiceName"
              value = "${var.service_name}-${var.environment}-inventory-worker"
            }
          }

          stat = "Average"
        }

        return_data = false
      }

      # If queue size is null, return 0.
      # Else if queue size and task count are 0, return 0.
      # Else if task count is 0, return 1001(> target_value).
      metrics {
        label       = "QueueSizePerTask"
        id          = "e1"
        expression  = "IF(FILL(m2, 0) > 0, FILL(m1, 0) / FILL(m2, 0), IF(FILL(m1, 0) > 1, 1001, 0))"
        return_data = true
      }
    }

    target_value       = 1000
    scale_in_cooldown  = 120
    scale_out_cooldown = 30
  }
}

# If queue size >= 1, then scale out.
resource "aws_appautoscaling_policy" "inventory_worker_queue_inventory_step_scale_out" {
  name               = "inventory-worker-queue-inventory-step-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.inventory_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.inventory_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.inventory_worker.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 30
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "inventory_worker_queue_inventory_scale_out" {
  alarm_name          = "inventory-worker-queue-inventory-scale-out"
  alarm_description   = "Scale inventory worker out when the inventory queue has more than one message"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "redis_key_size"
  namespace           = "ElastiCache/Prometheus"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_appautoscaling_policy.inventory_worker_queue_inventory_step_scale_out.arn]

  dimensions = {
    job = "redis_exporter"
    db  = "db0"
    key = "laravel-database-queues:inventory"
  }
}
