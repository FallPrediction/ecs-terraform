resource "aws_cloudwatch_log_group" "general_worker" {
  name              = "/ecs/general-worker"
  retention_in_days = var.retention_in_days
}
