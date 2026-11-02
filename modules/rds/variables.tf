variable "service_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t4g.micro"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ RDS deployment."
  default     = false
}

variable "db_name" {
  type        = string
  description = "RDS Database Name"
}

variable "db_username" {
  type        = string
  description = "RDS Username"
}
