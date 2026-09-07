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
