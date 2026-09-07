output "aws_iam_role_ec2_name" {
  description = "Name of the ec2 IAM role."
  value       = aws_iam_role.ec2.name
}

output "aws_iam_role_ec2_arn" {
  description = "Arn of the ec2 IAM role."
  value       = aws_iam_role.ec2.arn
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public1.id, aws_subnet.public2.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = [aws_subnet.private1.id, aws_subnet.private2.id]
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host."
  value       = aws_security_group.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP used by the self-managed bastion instance."
  value       = aws_instance.bastion.public_ip
}

output "nat_instance_id" {
  description = "ID of the self-managed NAT instance."
  value       = aws_instance.nat.id
}

output "key_pair_name" {
  description = "EC2 key pair name."
  value       = aws_key_pair.key_pair.key_name
}
