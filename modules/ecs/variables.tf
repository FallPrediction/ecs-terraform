variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "efs_id" {
  type        = string
  description = "EFS File System ID"
}

variable "efs_access_point_id" {
  type        = string
  description = "EFS Access Point ID"
}

variable "efs_security_group_id" {
  type = string
}

variable "rds_address" {
  type        = string
  description = "RDS Host"
}

variable "db_name" {
  type        = string
  description = "RDS Database Name"
}

variable "db_username" {
  type        = string
  description = "RDS Username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS password"
}

variable "redis_primary_address" {
  type = string
}

variable "app_key" {
  type      = string
  sensitive = true
}

variable "ecs_instance_type" {
  type = string
}
