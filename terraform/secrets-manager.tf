# Generate random password for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AWS Secrets Manager Secret for DB Username
resource "aws_secretsmanager_secret" "db_username" {
  name                    = "${var.name_prefix}-${var.environment}-db-username"
  description             = "Database username for ${var.name_prefix}-${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-db-username"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_username" {
  secret_id     = aws_secretsmanager_secret.db_username.id
  secret_string = var.db_username
}

# AWS Secrets Manager Secret for DB Password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name_prefix}-${var.environment}-db-password"
  description             = "Database password for ${var.name_prefix}-${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-db-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# AWS Secrets Manager Secret for full DB connection string
resource "aws_secretsmanager_secret" "db_connection_string" {
  name                    = "${var.name_prefix}-${var.environment}-db-connection"
  description             = "Database connection string for ${var.name_prefix}-${var.environment}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-db-connection"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_connection_string" {
  secret_id = aws_secretsmanager_secret.db_connection_string.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.database_name
  })

  depends_on = [aws_db_instance.main]
}