output "general_worker_service_name" {
  description = "ECS general worker service name."
  value       = aws_ecs_service.general_worker.name
}

output "general_worker_service_arn" {
  description = "ECS general worker service ARN."
  value       = aws_ecs_service.general_worker.arn
}

output "general_worker_capacity_provider_name" {
  value = aws_ecs_capacity_provider.general_worker_on_demand.name
}
