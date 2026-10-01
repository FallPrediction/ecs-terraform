output "inventory_worker_service_name" {
  description = "ECS inventory worker service name."
  value       = aws_ecs_service.inventory_worker.name
}

output "inventory_worker_service_arn" {
  description = "ECS inventory worker service ARN."
  value       = aws_ecs_service.inventory_worker.arn
}

output "inventory_worker_capacity_provider_name" {
  value = aws_ecs_capacity_provider.inventory_worker_on_demand.name
}
