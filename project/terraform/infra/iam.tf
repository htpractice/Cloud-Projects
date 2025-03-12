resource "aws_iam_role" "bastion_role" {
  name = "${var.environment}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bastion_read_only_policy" {
  name        = "${var.environment}-bastion-read-only-policy"
  description = "Read-only policy for bastion host to access EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_policy_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_read_only_policy.arn
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "${var.environment}-bastion-instance-profile"
  role = aws_iam_role.bastion_role.name
}