resource "aws_efs_file_system" "data" {
  encrypted       = true
  throughput_mode = "elastic"
  lifecycle_policy {
    transition_to_archive = "AFTER_90_DAYS"
  }
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.service_name}-${var.environment}-efs"
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.data.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_security_group" "efs" {
  name   = "${var.service_name}-${var.environment}-efs"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "data" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.data.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "laravel" {
  file_system_id = aws_efs_file_system.data.id

  # 強制將所有進入此 Access Point 的連線映射為 UID 33 (www-data)
  posix_user {
    uid = 33
    gid = 33
  }

  # 如果 EFS 內部對應的資料夾不存在，自動用 root 建立它並給予 755 權限
  root_directory {
    path = "/mnt/efs"
    creation_info {
      owner_uid   = 33
      owner_gid   = 33
      permissions = "755"
    }
  }
}
