# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AmazonECSInfrastructureRolePolicyForLoadBalancers.html
resource "aws_iam_role" "load_balancer_management" {
  name = "${var.service_name}-${var.environment}-ecs-alb-deployment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "load_balancer_management" {
  role       = aws_iam_role.load_balancer_management.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}
