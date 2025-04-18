/* # Temporarily commented out ECR resources
# ECR Repositories for application images

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}/backend" # Format: project/service
  image_tag_mutability = "MUTABLE" # Or IMMUTABLE if preferred

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Service     = "backend"
    Environment = "dev"
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}/frontend" # Format: project/service
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Service     = "frontend"
    Environment = "dev"
  }
}

# Outputs for ECR repository URLs
output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}
*/ 