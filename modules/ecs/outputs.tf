output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  value = aws_iam_role.app_task_role.arn
}

output "laravel_env_arn" {
  value = aws_ssm_parameter.laravel_env.arn
}

output "nginx_conf_arn" {
  value = aws_ssm_parameter.nginx_default_conf.arn
}

output "cluster_id" {
  value = aws_ecs_cluster.app.id
}

output "cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "capacity_provider_on_demand_name" {
  value = aws_ecs_capacity_provider.on_demand.name
}

output "capacity_provider_spot_name" {
  value = aws_ecs_capacity_provider.spot.name
}

output "on_demand_asg_name" {
  description = "On-demand Auto Scaling group backing the ECS capacity provider."
  value       = aws_autoscaling_group.on_demand.name
}

output "spot_asg_name" {
  description = "Spot Auto Scaling group backing the ECS capacity provider."
  value       = aws_autoscaling_group.spot.name
}
