resource "aws_iam_role" "common_role" {
  name = "${var.environment}-common-role"

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

# IAM Policy for ECR and EC2 Access
resource "aws_iam_policy" "ecr_ec2_policy" {
  name        = "${var.environment}-ecr-ec2-policy"
  description = "Policy for instances to access ECR and EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
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

resource "aws_iam_role_policy_attachment" "common_policy_attachment" {
  role       = aws_iam_role.common_role.name
  policy_arn = aws_iam_policy.ecr_ec2_policy.arn
}

resource "aws_iam_instance_profile" "common_instance_profile" {
  name = "${var.environment}-common-instance-profile"
  role = aws_iam_role.common_role.name
}