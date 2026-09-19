output "alb_arn_suffix" {
  value = aws_lb.api.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.api.arn_suffix
}

output "api_service_name" {
  description = "ECS API service name."
  value       = aws_ecs_service.api.name
}

output "api_service_arn" {
  description = "ECS API service ARN."
  value       = aws_ecs_service.api.arn
}

output "api_capacity_provider_name" {
  value = aws_ecs_capacity_provider.api_on_demand.name
}
