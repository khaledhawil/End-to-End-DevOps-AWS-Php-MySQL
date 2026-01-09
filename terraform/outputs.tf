output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint for EKS control plane"
}

output "eks_cluster_region" {
  value       = var.region
  description = "AWS region where the EKS cluster is located"
}

output "ecr_frontend_repository_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "The ECR repository URL for frontend"
}

output "ecr_logout_repository_url" {
  value       = aws_ecr_repository.logout.repository_url
  description = "The ECR repository URL for logout service"
}

output "ecr_users_repository_url" {
  value       = aws_ecr_repository.users.repository_url
  description = "The ECR repository URL for users service"
}

output "kube_config_command" {
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
  description = "Command to update kubeconfig for EKS cluster"
}

# Database outputs
output "db_host" {
  description = "The RDS MySQL host endpoint"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "The RDS MySQL port"
  value       = aws_db_instance.main.port
}

output "db_username" {
  description = "The RDS MySQL administrator username"
  value       = var.db_username
  sensitive   = true
}

output "db_password" {
  description = "The RDS MySQL administrator password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_name" {
  description = "The RDS MySQL database name"
  value       = var.database_name
}

# VPC outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# Secrets Manager outputs
output "db_username_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB username"
  value       = aws_secretsmanager_secret.db_username.arn
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB password"
  value       = aws_secretsmanager_secret.db_password.arn
}