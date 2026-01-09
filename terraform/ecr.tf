# AWS ECR Repository for Frontend
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.name_prefix}-${var.environment}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-${var.environment}-frontend"
  }
}

# AWS ECR Repository for Logout Service
resource "aws_ecr_repository" "logout" {
  name                 = "${var.name_prefix}-${var.environment}-logout"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-${var.environment}-logout"
  }
}

# AWS ECR Repository for Users Service
resource "aws_ecr_repository" "users" {
  name                 = "${var.name_prefix}-${var.environment}-users"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-${var.environment}-users"
  }
}

# ECR Lifecycle Policy for all repositories
resource "aws_ecr_lifecycle_policy" "frontend_policy" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "logout_policy" {
  repository = aws_ecr_repository.logout.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "users_policy" {
  repository = aws_ecr_repository.users.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
