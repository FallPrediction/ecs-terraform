output "alb_dns_name" {
  value = aws_lb.api.dns_name
}

output "api_capacity_provider_name" {
  value = aws_ecs_capacity_provider.api_on_demand.name
}
