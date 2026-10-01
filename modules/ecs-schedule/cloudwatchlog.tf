resource "aws_cloudwatch_log_group" "schedule" {
  name              = "/ecs/schedule"
  retention_in_days = var.retention_in_days
}
