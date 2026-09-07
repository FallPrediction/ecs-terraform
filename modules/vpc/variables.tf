variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_key" {
  type      = string
  sensitive = true
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR allowed to SSH into the bastion host."
}

variable "bastion_instance_type" {
  type = string
}

variable "nat_instance_type" {
  type = string
}
