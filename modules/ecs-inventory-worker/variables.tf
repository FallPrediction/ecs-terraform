variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "efs_id" {
  type        = string
  description = "EFS File System ID"
}

variable "efs_access_point_id" {
  type        = string
  description = "EFS Access Point ID"
}

variable "laravel_image" {
  type        = string
  description = "Laravel ECR Image URI"
}

variable "inventory_worker_desired_count" {
  type = number
}

variable "inventory_worker_max_count" {
  type = number
}

variable "retention_in_days" {
  type        = number
  description = "CloudWatch Logs retention in days."
  default     = 7
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "laravel_env_arn" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "capacity_provider_spot_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "inventory_worker_asg_min_size" {
  type = number
}

variable "inventory_worker_asg_max_size" {
  type = number
}

variable "inventory_worker_asg_desired_capacity" {
  type = number
}

variable "launch_template_id" {
  type = string
}
