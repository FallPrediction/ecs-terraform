terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }

  required_version = ">= 1.15"
}

provider "aws" {
  alias  = "ap-east-2"
  region = var.aws_region

  default_tags {
    tags = {
      Owner       = var.owner
      Environment = var.environment
      Service     = var.service_name
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  service_name          = var.service_name
  environment           = var.environment
  public_key            = var.public_key
  ssh_allowed_cidr      = var.ssh_allowed_cidr
  bastion_instance_type = var.bastion_instance_type
  nat_instance_type     = var.nat_instance_type

  providers = {
    aws = aws.ap-east-2
  }
}

module "rds" {
  source = "./modules/rds"

  service_name = var.service_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  db_password  = var.db_password
  db_name      = var.db_name
  db_username  = var.db_username

  providers = {
    aws = aws.ap-east-2
  }
}
