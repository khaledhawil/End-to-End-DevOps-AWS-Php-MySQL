-- Migration script to update existing database schema
-- Run this if you already have the database set up

USE task_manager;

-- Add priority column if it doesn't exist
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS priority ENUM('low', 'medium', 'high') DEFAULT 'medium' AFTER description;

-- Add due_date column if it doesn't exist
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS due_date DATE AFTER status;

-- Add updated_at to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- Add email column to users if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email VARCHAR(100) AFTER password;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_user_status ON tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_priority ON tasks(user_id, priority);
CREATE INDEX IF NOT EXISTS idx_due_date ON tasks(due_date);

-- Drop old index if it exists (will be replaced by compound index)
DROP INDEX IF EXISTS idx_user_tasks ON tasks;

-- Create better compound index
CREATE INDEX IF NOT EXISTS idx_user_tasks ON tasks(user_id, created_at);

SELECT 'Migration completed successfully!' as status;
