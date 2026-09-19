resource "aws_ssm_parameter" "laravel_env" {
  name        = "/${var.environment}/laravel/.env"
  type        = "SecureString"
  description = "Laravel environment file for the ECS service"
  value       = <<-EOT
    DB_CONNECTION=pgsql
    DB_HOST=${var.rds_address}
    DB_DATABASE=${var.db_name}
    DB_USERNAME=${var.db_username}
    DB_PASSWORD=${var.db_password}
    SESSION_DRIVER=redis
    REDIS_CLIENT=phpredis
    REDIS_HOST=${var.redis_primary_address}
    CACHE_STORE=redis
    QUEUE_CONNECTION=redis
    LOG_STACK=stdout
    LOG_STDOUT_FORMATTER=\Monolog\Formatter\JsonFormatter
    LOG_STDERR_FORMATTER=\Monolog\Formatter\JsonFormatter
    APP_KEY=${var.app_key}
    AWS_DEFAULT_REGION=${var.aws_region}
    EFS_DISK_ROOT=/var/www/html/storage/efs
  EOT
}

resource "aws_ssm_parameter" "nginx_default_conf" {
  name        = "/${var.environment}/nginx/default.conf"
  type        = "SecureString"
  description = "Nginx configuration for the ECS Laravel service"
  value       = <<-EOT
    server {
      listen 80;
      server_name _;

      root /var/www/html/public;
      index index.php index.html;

      access_log /var/log/nginx/access.log;
      error_log  /var/log/nginx/error.log;

      location /health/liveness {
          return 200;
      }

      # Readiness is available only on the ALB health-check port (8080).
      location = /api/health/readiness {
          return 404;
      }

      location / {
          try_files $uri $uri/ /index.php?$query_string;
      }

      location ~ \.php$ {
          include fastcgi_params;
          fastcgi_pass 127.0.0.1:9000;
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param PATH_INFO $fastcgi_path_info;
      }

      location ~ /\. {
          deny all;
      }

    }

    # This port is not exposed by an ALB listener. It only serves the target
    # group's health check, which connects directly from the ALB to the task.
    server {
      listen 8080 default_server;
      server_name _;

      root /var/www/html/public;

      location = /api/health/readiness {
          include fastcgi_params;
          fastcgi_pass 127.0.0.1:9000;
          fastcgi_param SCRIPT_FILENAME $document_root/index.php;
          fastcgi_param SCRIPT_NAME /index.php;
          fastcgi_param REQUEST_URI /api/health/readiness;
      }

      location / {
          return 404;
      }
    }
  EOT
}
