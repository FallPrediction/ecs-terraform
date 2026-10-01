data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

resource "aws_launch_template" "app" {
  name_prefix            = "${var.service_name}-${var.environment}-ecs-"
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type          = var.ecs_instance_type
  update_default_version = true

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs.id]
  }

  # 設定 ECS config、並設定掛載 EFS
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.app.name}" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true" >> /etc/ecs/ecs.config

    dnf install -y amazon-efs-utils

    mkdir -p /mnt/efs
    mount -t efs -o tls,accesspoint=${var.efs_access_point_id} ${var.efs_id}:/ /mnt/efs

    echo "${var.efs_id}:/ /mnt/efs efs _netdev,tls,accesspoint=${var.efs_access_point_id} 0 0" >> /etc/fstab
    
    systemctl restart ecs --no-block
    EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.service_name}-${var.environment}-ecs-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
