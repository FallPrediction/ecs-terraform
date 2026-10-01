output "efs_id" {
  value = aws_efs_file_system.data.id
}

output "efs_access_point_id" {
  value = aws_efs_access_point.laravel.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}
