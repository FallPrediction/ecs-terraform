# 將 ECS service api 註冊為可擴充目標
resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.api_max_count
  min_capacity       = var.api_desired_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api-alb" {
  name               = "api-request-scaling-with-canary"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 5000 # 目標每個 Task 的平均請求數

    customized_metric_specification {
      # 1. 取得 Target Group A 的總請求數 (RequestCount)
      metrics {
        id = "requests_a"
        metric_stat {
          metric {
            namespace   = "AWS/ApplicationELB"
            metric_name = "RequestCount"
            dimensions {
              name  = "LoadBalancer"
              value = aws_lb.api.arn_suffix
            }

            dimensions {
              name  = "TargetGroup"
              value = aws_lb_target_group.a.arn_suffix
            }
          }
          stat   = "Sum"
        }
        return_data = false
      }

      # 2. 取得 Target Group B 的總請求數 (RequestCount)
      metrics {
        id = "requests_b"
        metric_stat {
          metric {
            namespace   = "AWS/ApplicationELB"
            metric_name = "RequestCount"

            dimensions {
              name  = "LoadBalancer"
              value = aws_lb.api.arn_suffix
            }

            dimensions {
              name  = "TargetGroup"
              value = aws_lb_target_group.b.arn_suffix
            }
          }
          stat   = "Sum"
        }
        return_data = false
      }

      # 3. 取得目前處於 RUNNING 狀態的 Task 數量
      metrics {
        id = "task_count"
        metric_stat {
          metric {
            namespace   = "AWS/ECS"
            metric_name = "RunningTaskCount"

            dimensions {
              name  = "ClusterName"
              value = var.cluster_name
            }

            dimensions {
              name  = "ServiceName"
              value = aws_ecs_service.api.name
            }
          }
          stat   = "Average"
        }
        return_data = false
      }

      # 4. 透過 Metric Math 計算平均每 Task 請求數
      metrics {
        id          = "requests_per_task"
        expression  = "IF(task_count > 0, (requests_a + requests_b) / task_count, 0)"
        label       = "Requests Per Running Task"
        return_data = true
      }
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "api-cpu" {
  name               = "api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      # See https://docs.aws.amazon.com/autoscaling/plans/APIReference/API_PredefinedScalingMetricSpecification.html
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60.0 # 視實際業務負載調整 (例如 60% ~ 70%)
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
