data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.service_name}-${var.environment}-key-pair"
  public_key = var.public_key
}

resource "aws_instance" "bastion" {
  # Amazon Linux 2023, arm64
  ami                         = "ami-0d1dae8efa2744df8"
  instance_type               = var.bastion_instance_type
  availability_zone           = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = aws_subnet.public1.id
  key_name                    = aws_key_pair.key_pair.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  tags = {
    Name = "${var.service_name}-${var.environment}-bastion"
  }
}

resource "aws_instance" "nat" {
  # Amazon Linux 2023, arm64
  ami                         = "ami-0d1dae8efa2744df8"
  instance_type               = var.nat_instance_type
  availability_zone           = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids      = [aws_security_group.nat.id]
  subnet_id                   = aws_subnet.public1.id
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = file("iptable-nat.sh")

  tags = {
    Name = "${var.service_name}-${var.environment}-nat"
  }
}
