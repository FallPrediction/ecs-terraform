variable "owner" {
  type        = string
  description = "Service Owner"
}

variable "service_name" {
  type        = string
  description = "Service name used for resource names and tags. Must be lowercase alphanumeric."
  default     = "laravel"
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "ap-east-2"
}

variable "public_key" {
  type      = string
  sensitive = true
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH into the bastion host."

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid IPv4 or IPv6 CIDR block, for example 203.0.113.10/32."
  }
}

variable "bastion_instance_type" {
  type        = string
  description = "Small bastion instance type for production."
  default     = "t4g.nano"
}

variable "nat_instance_type" {
  type        = string
  description = "Small self-managed NAT instance type for production."
  default     = "t4g.nano"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type        = string
  description = "RDS Database Name"
}

variable "db_username" {
  type        = string
  description = "RDS Username"
}

variable "app_key" {
  type      = string
  sensitive = true
}

variable "ecs_instance_type" {
  type        = string
  description = "Small ECS container instance type for production."
}

variable "asg_min_size" {
  type        = number
  description = "Minimum ECS ASG size. Set to 2 for higher availability."
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Maximum ECS ASG size."
  default     = 3

  validation {
    condition     = var.asg_max_size >= 1
    error_message = "asg_max_size must be at least 1."
  }
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired ECS ASG capacity."
  default     = 2

  validation {
    condition     = var.asg_desired_capacity >= var.asg_min_size && var.asg_desired_capacity <= var.asg_max_size
    error_message = "ecs_desired_capacity must be between asg_min_size and asg_max_size."
  }
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
  type        = number
  description = "Desired API ECS service task count. Set to 2 for higher availability."
  default     = 2
}

variable "api_max_count" {
  type        = number
  description = "Max API ECS service task count. Must higher than api_desired_count."
  default     = 3
}
