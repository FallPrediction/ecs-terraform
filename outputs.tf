output "bastion_public_ip" {
  value = module.vpc.bastion_public_ip
}

output "alb_dns_name" {
  value = module.ecs-api.alb_dns_name
}
