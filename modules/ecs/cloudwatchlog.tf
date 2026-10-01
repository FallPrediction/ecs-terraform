resource "aws_cloudwatch_log_group" "ecs_containerinsights" {
  name              = "/aws/ecs/containerinsights/${aws_ecs_cluster.app.name}/performance"
  retention_in_days = 1
}
