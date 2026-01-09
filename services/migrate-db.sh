#!/bin/bash
# Database Migration Helper Script

echo "🔄 Starting database migration..."

# Check if MySQL container is running
if ! docker ps | grep -q mysql; then
    echo "❌ MySQL container is not running. Please start it first with: docker-compose up -d mysql"
    exit 1
fi

echo "📊 Running migration script..."

# Run the migration SQL file
docker exec -i $(docker ps -qf "name=mysql") mysql -uroot -ppassword task_manager < migrate-db.sql

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo ""
    echo "📋 Verifying database schema..."
    docker exec -i $(docker ps -qf "name=mysql") mysql -uroot -ppassword task_manager -e "DESCRIBE tasks;"
    echo ""
    docker exec -i $(docker ps -qf "name=mysql") mysql -uroot -ppassword task_manager -e "SHOW INDEX FROM tasks;"
else
    echo "❌ Migration failed. Please check the error messages above."
    exit 1
fi
