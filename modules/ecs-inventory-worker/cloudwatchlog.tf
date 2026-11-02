resource "aws_cloudwatch_log_group" "inventory_worker" {
  name              = "/ecs/inventory-worker"
  retention_in_days = var.retention_in_days
}
