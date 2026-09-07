# Trusted entities
data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm_for_ec2" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2" {
  name               = "${var.service_name}-${var.environment}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm_for_ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = data.aws_iam_policy.ssm_for_ec2.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.service_name}-${var.environment}-ec2"
  role = aws_iam_role.ec2.name
}
