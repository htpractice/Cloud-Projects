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

# IAM Role for Jenkins and App Nodes
resource "aws_iam_role" "jenkins_app_role" {
  name = "${var.environment}-jenkins-app-role"

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

# IAM Policy for ECR Access
resource "aws_iam_policy" "ecr_policy" {
  name        = "${var.environment}-ecr-policy"
  description = "Policy for Jenkins and app nodes to access ECR"

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

resource "aws_iam_role_policy_attachment" "jenkins_app_policy_attachment" {
  role       = aws_iam_role.jenkins_app_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_app_instance_profile" {
  name = "${var.environment}-jenkins-app-instance-profile"
  role = aws_iam_role.jenkins_app_role.name
}