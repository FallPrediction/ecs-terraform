resource "aws_autoscaling_group" "spot" {
  name                = "${var.service_name}-${var.environment}-ecs-asg-spot"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 0
  max_size            = 2
  desired_capacity    = 0
  metrics_granularity = "1Minute" # Enable GroupInServiceInstances metric
  enabled_metrics     = ["GroupInServiceInstances"]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0                          # 100% 採用 Spot
      spot_allocation_strategy                 = "price-capacity-optimized" # 自動選擇容量充足且價格優的機型
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app.id
        version            = "$Latest"
      }

      # 使用 Attribute-Based Instance Selection，也可以直接指定 instance_type
      override {
        instance_requirements {
          vcpu_count {
            min = 2
          }
          memory_mib {
            min = 1843
          }
        }
      }
    }
  }

  # ECS Capacity Provider 的 Managed Termination Protection 必須搭配 ASG 的
  # instance scale-in protection，避免 ECS 正在使用的 instance 被 ASG 終止。
  protect_from_scale_in = true

  health_check_type         = "ELB"
  health_check_grace_period = 60 # 給予 1 分鐘緩衝讓 ECS Agent 啟動

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
