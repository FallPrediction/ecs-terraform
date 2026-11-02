variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "retention_in_days" {
  type        = number
  description = "CloudWatch Logs retention in days."
  default     = 7
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "launch_template_id" {
  type = string
}

variable "redis_primary_address" {
  type = string
}
