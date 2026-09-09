resource "aws_cloudwatch_log_group" "app_php" {
  name              = "/ecs/app-php"
  retention_in_days = var.retention_in_days
}

resource "aws_cloudwatch_log_group" "app_nginx" {
  name              = "/ecs/app-nginx"
  retention_in_days = var.retention_in_days
}
