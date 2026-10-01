resource "aws_ecs_task_definition" "inventory_worker" {
  family                   = "${var.service_name}-${var.environment}-inventory-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 1536
  memory                   = 1843
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  volume {
    name = "efs-storage"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED" # 啟用 IAM 驗證，確保 Access Point 權限生效
      }
    }
  }

  container_definitions = jsonencode([
    {
      name        = "php-fpm"
      image       = var.laravel_image
      essential   = true
      stopTimeout = 60
      mountPoints = [
        {
          sourceVolume  = "efs-storage"
          containerPath = "/mnt/efs"
          readOnly      = false
        }
      ]
      entryPoint = ["/bin/sh", "-ec"]
      command = [
        <<-EOT
          printf '%s\n' "$${LARAVEL_ENV_FILE}" > /var/www/html/.env && \
          unset LARAVEL_ENV_FILE && \
          jq -r '"ECS_TASK_ARN=\(.TaskARN)\nECS_TASK_FAMILY=\(.TaskDefinitionFamily)\nECS_TASK_REVISION=\(.TaskDefinitionRevision)"' $ECS_CONTAINER_METADATA_FILE >> /var/www/html/.env && \
          php artisan optimize --no-interaction && \
          php artisan queue:work --queue=inventory
        EOT
      ]
      secrets = [
        {
          name      = "LARAVEL_ENV_FILE"
          valueFrom = var.laravel_env_arn
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "pgrep -f 'artisan queue:work' > /dev/null || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30 # 設置合適的時間加快部署速度
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/inventory-worker"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "inventory-worker"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "inventory_worker" {
  name            = "${var.service_name}-${var.environment}-inventory-worker"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.inventory_worker.arn
  desired_count   = var.inventory_worker_desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_on_demand_name
    weight            = 0
    base              = 1 # 前 X 個為 on_demand
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_spot_name
    weight            = 1 # 超過 X 個全部用 spot
    base              = 0
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # 盡量避免開開關關 task，因此 disable AZ rebalance
  availability_zone_rebalancing      = "DISABLED"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
