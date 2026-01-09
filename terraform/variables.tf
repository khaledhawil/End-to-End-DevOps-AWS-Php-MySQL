variable "region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for the name of resources"
  type        = string
  default     = "cluster-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "The RDS Database Username"
  type        = string
  default     = "admin"
}

variable "database_name" {
  description = "The RDS Database Name"
  type        = string
  default     = "task_manager"
}