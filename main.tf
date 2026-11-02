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
}

module "rds" {
  source = "./modules/rds"

  service_name = var.service_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  db_password  = var.db_password
  db_name      = var.db_name
  db_username  = var.db_username
}

module "efs" {
  source = "./modules/efs"

  service_name       = var.service_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "elasticache" {
  source = "./modules/elasticache"

  service_name       = var.service_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

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

  depends_on = [
    module.vpc,
    module.rds,
    module.efs,
    module.elasticache
  ]
}

module "ecs-api" {
  source = "./modules/ecs-api"

  service_name                = var.service_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  efs_id                      = module.efs.efs_id
  efs_access_point_id         = module.efs.efs_access_point_id
  laravel_image               = var.laravel_image
  task_execution_role_arn     = module.ecs.task_execution_role_arn
  task_role_arn               = module.ecs.task_role_arn
  laravel_env_arn             = module.ecs.laravel_env_arn
  cluster_id                  = module.ecs.cluster_id
  cluster_name                = module.ecs.cluster_name
  capacity_provider_spot_name = module.ecs.capacity_provider_spot_name
  private_subnet_ids          = module.vpc.private_subnet_ids
  nginx_image                 = var.nginx_image
  ecs_security_group_id       = module.ecs.ecs_security_group_id
  vpc_id                      = module.vpc.vpc_id
  public_subnet_ids           = module.vpc.public_subnet_ids
  launch_template_id          = module.ecs.launch_template_id
  nginx_conf_arn              = module.ecs.nginx_conf_arn
  alb_security_group_id       = module.ecs.alb_security_group_id
  api_asg_min_size            = var.api_asg_min_size
  api_asg_max_size            = var.api_asg_max_size
  api_asg_desired_capacity    = var.api_asg_desired_capacity
  api_desired_count           = var.api_desired_count
  api_max_count               = var.api_desired_count < var.api_max_count ? var.api_max_count : var.api_desired_count

  depends_on = [
    module.vpc,
    module.efs,
    module.ecs
  ]
}

module "ecs-inventory-worker" {
  source = "./modules/ecs-inventory-worker"

  service_name                          = var.service_name
  environment                           = var.environment
  aws_region                            = var.aws_region
  efs_id                                = module.efs.efs_id
  efs_access_point_id                   = module.efs.efs_access_point_id
  laravel_image                         = var.laravel_image
  task_execution_role_arn               = module.ecs.task_execution_role_arn
  task_role_arn                         = module.ecs.task_role_arn
  laravel_env_arn                       = module.ecs.laravel_env_arn
  cluster_id                            = module.ecs.cluster_id
  cluster_name                          = module.ecs.cluster_name
  capacity_provider_spot_name           = module.ecs.capacity_provider_spot_name
  private_subnet_ids                    = module.vpc.private_subnet_ids
  launch_template_id                    = module.ecs.launch_template_id
  ecs_security_group_id                 = module.ecs.ecs_security_group_id
  inventory_worker_asg_min_size         = var.inventory_worker_asg_min_size
  inventory_worker_asg_max_size         = var.inventory_worker_asg_max_size
  inventory_worker_asg_desired_capacity = var.inventory_worker_asg_desired_capacity
  inventory_worker_desired_count        = var.inventory_worker_desired_count
  inventory_worker_max_count            = var.inventory_worker_desired_count < var.inventory_worker_max_count ? var.inventory_worker_max_count : var.inventory_worker_desired_count

  depends_on = [
    module.vpc,
    module.efs,
    module.ecs
  ]
}

module "ecs-general-worker" {
  source = "./modules/ecs-general-worker"

  service_name                        = var.service_name
  environment                         = var.environment
  aws_region                          = var.aws_region
  efs_id                              = module.efs.efs_id
  efs_access_point_id                 = module.efs.efs_access_point_id
  laravel_image                       = var.laravel_image
  task_execution_role_arn             = module.ecs.task_execution_role_arn
  task_role_arn                       = module.ecs.task_role_arn
  laravel_env_arn                     = module.ecs.laravel_env_arn
  cluster_id                          = module.ecs.cluster_id
  cluster_name                        = module.ecs.cluster_name
  capacity_provider_spot_name         = module.ecs.capacity_provider_spot_name
  private_subnet_ids                  = module.vpc.private_subnet_ids
  launch_template_id                  = module.ecs.launch_template_id
  ecs_security_group_id               = module.ecs.ecs_security_group_id
  general_worker_asg_min_size         = var.general_worker_asg_min_size
  general_worker_asg_max_size         = var.general_worker_asg_max_size
  general_worker_asg_desired_capacity = var.general_worker_asg_desired_capacity
  general_worker_desired_count        = var.general_worker_desired_count
  general_worker_max_count            = var.general_worker_desired_count < var.general_worker_max_count ? var.general_worker_max_count : var.general_worker_desired_count

  depends_on = [
    module.vpc,
    module.efs,
    module.ecs
  ]
}

# 關聯 cluster 和 capacity provider
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name = module.ecs.cluster_name

  capacity_providers = [
    module.ecs-api.api_capacity_provider_name,
    module.ecs-inventory-worker.inventory_worker_capacity_provider_name,
    module.ecs-general-worker.general_worker_capacity_provider_name,
    module.ecs.capacity_provider_spot_name
  ]
}
