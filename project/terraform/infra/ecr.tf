# Create ECR repository
resource "aws_ecr_repository" "jenkins_app_repo" {
  name = "${var.environment}-jenkins-app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "${var.environment}-jenkins-app-repo"
    Environment = var.environment
  }
}

# Output the repository URL
output "jenkins_app_repo_url" {
  value = aws_ecr_repository.jenkins_app_repo.repository_url
}