resource "aws_lb_target_group" "api" {
  port        = 80
  protocol    = "HTTP"
  target_type = "ip" # 若 ECS task network mode 為 awsvpc，則 ALB target type 需為 IP
  vpc_id      = var.vpc_id
  slow_start  = 30
  # See https://blogs.reliablepenguin.com/2025/12/20/deregistration-delay-on-aws-application-load-balancers-alb
  deregistration_delay = 60
  health_check {
    # Health checks use Nginx's dedicated, non-public health port. Normal
    # listener traffic continues to be routed to target port 80.
    port                = "8080"
    path                = "/api/health/readiness"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2 # 最多 interval * unhealthy_threshold 秒移除 unhealthy host
  }
}

resource "aws_lb" "api" {
  name            = "${var.service_name}-${var.environment}-alb"
  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
