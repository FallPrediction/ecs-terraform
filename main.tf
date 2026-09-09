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

module "efs" {
  source = "./modules/efs"

  service_name       = var.service_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  providers = {
    aws = aws.ap-east-2
  }
}

module "elasticache" {
  source = "./modules/elasticache"

  service_name       = var.service_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  providers = {
    aws = aws.ap-east-2
  }

  depends_on = [
    module.vpc
  ]
}

module "ecs" {
  source = "./modules/ecs"

  service_name              = var.service_name
  environment               = var.environment
  aws_region                = var.aws_region
  efs_id                    = module.efs.efs_id
  efs_access_point_id       = module.efs.efs_access_point_id
  efs_security_group_id     = module.efs.efs_security_group_id
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  bastion_security_group_id = module.vpc.bastion_security_group_id
  rds_address               = module.rds.rds_address
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  redis_primary_address     = module.elasticache.redis_primary_address
  app_key                   = var.app_key
  ecs_instance_type         = var.ecs_instance_type
  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  asg_desired_capacity      = var.asg_desired_capacity

  providers = {
    aws = aws.ap-east-2
  }

  depends_on = [
    module.vpc,
    module.rds,
    module.efs,
    module.elasticache
  ]
}
