resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.service_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name   = "${var.service_name}-${var.environment}-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_replication_group" "redis" {
  description          = "Cost-effective Redis cluster for testing"
  replication_group_id = "${var.service_name}-${var.environment}-redis-cluster"
  node_type            = "cache.t4g.micro"

  num_cache_clusters = var.num_cache_clusters

  engine         = "redis"
  engine_version = "7.1"
  port           = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  cluster_mode               = "disabled" # 測試用
  automatic_failover_enabled = false
  multi_az_enabled           = false
  snapshot_retention_limit   = 0     # 測試停用自動快照備份
  at_rest_encryption_enabled = false # 測試環境可視需求停用傳輸/靜態加密
  transit_encryption_enabled = false
}
