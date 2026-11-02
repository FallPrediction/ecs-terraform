resource "aws_cloudwatch_log_group" "redis-exporter" {
  name              = "/ecs/redis-exporter"
  retention_in_days = var.retention_in_days
}
