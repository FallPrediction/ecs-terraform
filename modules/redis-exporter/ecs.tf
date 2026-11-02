resource "aws_ecs_task_definition" "redis_exporter" {
  family                   = "${var.service_name}-${var.environment}-redis-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.redis_exporter_task_execution_role.arn
  task_role_arn            = aws_iam_role.redis_exporter_task_role.arn

  # In the redis-exporter container, write the environment variable $PROMETHEUS_CONFIG_CONTENT to a file; the cloudwatch-agent container will be able to use that file, since both containers share the same storage volume.
  # See https://docs.aws.amazon.com/zh_tw/AmazonECS/latest/developerguide/specifying-sensitive-data.html#security-secrets-management-recommendations-mount-secret-volumes
  volume {
    name = "cw-agent-config"
  }

  container_definitions = jsonencode([
    {
      name       = "redis-exporter"
      image      = "oliver006/redis_exporter:v1.91.1-alpine"
      essential  = true
      entrypoint = ["/bin/sh", "-c"]
      command = [
        "echo \"$PROMETHEUS_CONFIG_CONTENT\" > /tmp/prometheus.yaml && exec /redis_exporter -redis.addr=redis://${var.redis_primary_address}:6379 -check-keys=laravel-database-queues:inventory,laravel-database-queues:invoice,laravel-database-queues:notification"
      ]
      secrets = [
        {
          name      = "PROMETHEUS_CONFIG_CONTENT"
          valueFrom = aws_ssm_parameter.redis_exporter_prometheus_yaml.arn
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "cw-agent-config"
          containerPath = "/tmp"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget --spider http://127.0.0.1:9121/metrics || exit 1"]
        interval    = 5
        timeout     = 5
        retries     = 3
        startPeriod = 5
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/redis-exporter"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "exporter"
        }
      }
    },
    {
      name      = "cloudwatch-agent"
      image     = "amazon/cloudwatch-agent:latest"
      essential = true
      mountPoints = [
        {
          sourceVolume  = "cw-agent-config"
          containerPath = "/opt/aws/amazon-cloudwatch-agent/etc/custom"
        }
      ]
      secrets = [
        {
          name      = "CW_CONFIG_CONTENT"
          valueFrom = aws_ssm_parameter.redis_exporter_cw_agent_config.arn
        }
      ]
      dependsOn = [
        {
          containerName = "redis-exporter"
          condition     = "HEALTHY"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/redis-exporter"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cw-agent"
        }
      }
    }
  ])
}

resource "aws_ecs_capacity_provider" "redis_exporter_on_demand" {
  name = "${var.service_name}-${var.environment}-capacity-provider-redis-exporter-on-demand"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.redis_exporter_on_demand.arn
    managed_termination_protection = "ENABLED" # See https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/modules/cluster/README.md

    managed_scaling {
      status          = "ENABLED" # See https://github.com/terraform-aws-modules/terraform-aws-ecs/blob/master/modules/cluster/README.md
      target_capacity = 100       # 盡量讓 Instance 滿載任務
    }
  }
}

resource "aws_ecs_service" "redis_exporter" {
  name            = "${var.service_name}-${var.environment}-redis-exporter"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.redis_exporter.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.redis_exporter_on_demand.name
    base              = 0
    weight            = 1
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  availability_zone_rebalancing = "DISABLED"
  # 同時間只能 1 個 task running
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
