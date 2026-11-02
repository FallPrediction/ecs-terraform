output "rds_address" {
  value = aws_db_instance.default.address
}

output "rds_identifier" {
  description = "RDS DB instance identifier."
  value       = aws_db_instance.default.identifier
}
