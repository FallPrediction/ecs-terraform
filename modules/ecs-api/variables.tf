variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "laravel_image" {
  type        = string
  description = "Laravel ECR Image URI"
}

variable "nginx_image" {
  type        = string
  description = "Nginx ECR Image URI"
}

variable "api_desired_count" {
  type = number
}

variable "api_max_count" {
  type = number
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "retention_in_days" {
  type        = number
  description = "CloudWatch Logs retention in days."
  default     = 7
}

variable "laravel_env_arn" {
  type = string
}

variable "nginx_conf_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "efs_id" {
  type        = string
  description = "EFS File System ID"
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "efs_access_point_id" {
  type        = string
  description = "EFS Access Point ID"
}

variable "capacity_provider_spot_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "api_asg_min_size" {
  type = number
}

variable "api_asg_max_size" {
  type = number
}

variable "api_asg_desired_capacity" {
  type = number
}

variable "launch_template_id" {
  type = string
}
