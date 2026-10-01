resource "aws_ecs_cluster" "app" {
  name = "${var.service_name}-${var.environment}"
}

resource "aws_ecs_capacity_provider" "spot" {
  name = "${var.service_name}-${var.environment}-capacity-provider-spot"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.spot.arn
    managed_termination_protection = "ENABLED" # See https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/modules/cluster/README.md

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED" # See https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/modules/cluster/README.md
      target_capacity           = 100       # 盡量讓 Instance 滿載任務
    }
  }
}
