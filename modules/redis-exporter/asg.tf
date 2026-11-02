resource "aws_autoscaling_group" "redis_exporter_on_demand" {
  name                = "${var.service_name}-${var.environment}-ecs-asg-redis-exporter-on-demand"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  metrics_granularity = "1Minute" # Enable GroupInServiceInstances metric
  enabled_metrics     = ["GroupInServiceInstances"]

  # ECS Capacity Provider 的 Managed Termination Protection 必須搭配 ASG 的
  # instance scale-in protection，避免 ECS 正在使用的 instance 被 ASG 終止。
  protect_from_scale_in = true

  health_check_type         = "EC2"
  health_check_grace_period = 60 # 給予 1 分鐘緩衝讓 ECS Agent 啟動

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  # 必須加入這個 Tag 讓 ECS 能夠識別並管理
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
