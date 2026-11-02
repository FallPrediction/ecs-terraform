resource "aws_security_group" "alb" {
  name   = "${var.service_name}-${var.environment}-alb"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_api" {
  name   = "${var.service_name}-${var.environment}-ecs-api"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Only the ALB can reach Nginx's dedicated readiness-check port.
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.efs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_allow_ecs_api" {
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
  security_group_id            = var.efs_security_group_id
  referenced_security_group_id = aws_security_group.ecs_api.id
}

resource "aws_security_group" "ecs" {
  name   = "${var.service_name}-${var.environment}-ecs"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.efs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_allow_ecs" {
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
  security_group_id            = var.efs_security_group_id
  referenced_security_group_id = aws_security_group.ecs.id
}
