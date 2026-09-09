resource "aws_ecs_task_definition" "api" {
  family                   = "${var.service_name}-${var.environment}-api"
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

  # Main container stopTimeout should >= ALB deregistration_delay
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
        # 讀取 ECS task 資訊並放入 env
        "printf '%s\\n' \"$${LARAVEL_ENV_FILE}\" > /var/www/html/.env && unset LARAVEL_ENV_FILE && jq -r '\"ECS_TASK_ARN=\\(.TaskARN)\nECS_TASK_FAMILY=\\(.TaskDefinitionFamily)\nECS_TASK_REVISION=\\(.TaskDefinitionRevision)\"' $ECS_CONTAINER_METADATA_FILE >> /var/www/html/.env && php artisan optimize --no-interaction && exec php-fpm"
      ]
      secrets = [
        {
          name      = "LARAVEL_ENV_FILE"
          valueFrom = var.laravel_env_arn
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30 # 設置合適的時間加快部署速度
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/app-php"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "php"
        }
      }
    },
    {
      name       = "nginx"
      image      = var.nginx_image
      essential  = true
      entryPoint = ["/bin/sh", "-ec"]
      command = [
        "mkdir -p /etc/nginx/vhost && printf '%s' \"$${NGINX_DEFAULT_CONF}\" > /etc/nginx/conf.d/default.conf && nginx -t && exec nginx -g 'daemon off;'"
      ]
      secrets = [
        {
          name      = "NGINX_DEFAULT_CONF"
          valueFrom = var.nginx_conf_arn
        }
      ]
      portMappings = [
        {
          containerPort = 80 # network_mode 為 awsvpc 時，只需指定 containerPort，並忽略 hostPort
          protocol      = "tcp"
        },
        {
          # ALB uses this port only for target-group health checks.
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      dependsOn = [
        {
          containerName = "php-fpm"
          condition     = "HEALTHY"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q -O /dev/null http://localhost/health/liveness || exit 1"]
        interval    = 5 # 縮短秒數以加快部署速度
        timeout     = 5
        retries     = 3
        startPeriod = 5 # 縮短秒數以加快部署速度
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/app-nginx"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${var.service_name}-${var.environment}-api"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_on_demand_name
    weight            = 0
    base              = var.api_desired_count # 前 X 個為 on_demand
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_spot_name
    weight            = 1 # 超過 X 個全部用 spot
    base              = 0
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # 若 network mode 為 awsvpc，則必須設置 network_configuration
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # AZ rebalancing enabled 時，max percent 必須 > 100
  availability_zone_rebalancing      = "ENABLED"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 150

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
