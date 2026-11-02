data "aws_caller_identity" "current" {}


resource "aws_iam_role" "redis_exporter_task_execution_role" {
  name = "${var.service_name}-${var.environment}-redis-exporter-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redis_exporter_task_execution_role_policy" {
  role       = aws_iam_role.redis_exporter_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "redis_exporter_task_execution_ssm_policy" {
  name = "${var.service_name}-${var.environment}-redis-exporter-task-execution-ssm"
  role = aws_iam_role.redis_exporter_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters"
        ]
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.redis_exporter_prometheus_yaml.arn,
          aws_ssm_parameter.redis_exporter_cw_agent_config.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role" "redis_exporter_task_role" {
  name = "redis-exporter-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Condition = {
          ArnLike = {
            "aws:SourceArn" : "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          },
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.redis_exporter_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
