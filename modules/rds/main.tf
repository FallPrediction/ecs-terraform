data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "rds" {
  name   = "${var.service_name}-${var.environment}-rds"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_subnet" "rds1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.208.0/20"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.service_name}-${var.environment}-rds-1"
  }
}

resource "aws_subnet" "rds2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.240.0/20"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.service_name}-${var.environment}-rds-2"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.service_name}-${var.environment}-rds"
  subnet_ids = [aws_subnet.rds1.id, aws_subnet.rds2.id]
}

resource "aws_route_table" "rds" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "rds1_rt_association" {
  subnet_id      = aws_subnet.rds1.id
  route_table_id = aws_route_table.rds.id
}

resource "aws_route_table_association" "rds2_rt_association" {
  subnet_id      = aws_subnet.rds2.id
  route_table_id = aws_route_table.rds.id
}

resource "aws_db_instance" "default" {
  identifier                 = "${var.service_name}-${var.environment}"
  storage_type               = "gp3"
  allocated_storage          = 20
  max_allocated_storage      = 0 # 測試用
  storage_encrypted          = true
  db_name                    = var.db_name
  engine                     = "postgres"
  engine_version             = "18.6"
  auto_minor_version_upgrade = true
  instance_class             = var.instance_class
  username                   = var.db_username
  password                   = var.db_password
  backup_retention_period    = 0 # 測試用
  # backup_window              = "18:00-19:00" # 測試用
  # maintenance_window         = "sun:19:00-sun:20:00" # 測試用
  deletion_protection       = false # 測試用
  skip_final_snapshot       = true  # 測試用
  final_snapshot_identifier = "${var.service_name}-${var.environment}-final-snapshot"
  multi_az                  = var.multi_az
  db_subnet_group_name      = aws_db_subnet_group.rds.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
}
