# Create ECR repositories
# Jenkins Image repository
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

# Movie App Image repository
resource "aws_ecr_repository" "movie_app_repo" {
  name = "${var.environment}-movie-app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "${var.environment}-movie-app-repo"
    Environment = var.environment
  }
}