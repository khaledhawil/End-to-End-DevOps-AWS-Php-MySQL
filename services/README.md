# Task Manager - Microservices Architecture

Modern task management application built with microservices architecture.

## Architecture

```
services/
├── frontend/          # React + Vite
├── auth-service/      # Node.js + Express (Authentication)
├── task-service/      # Python + Flask (Task Management)
├── init-db.sql        # Database schema
└── docker-compose.yml # Local development
```

## Services

### Frontend (React + Vite)
- **Port:** 3000
- **Tech:** React 18, Vite, Axios
- **Features:** Login, Register, Task Dashboard

### Auth Service (Node.js)
- **Port:** 8001
- **Tech:** Express, bcryptjs, JWT
- **Endpoints:**
  - POST `/api/auth/register` - User registration
  - POST `/api/auth/login` - User login
  - POST `/api/auth/verify` - Token verification

### Task Service (Python)
- **Port:** 8002
- **Tech:** Flask, mysql-connector
- **Endpoints:**
  - GET `/api/tasks` - List tasks
  - POST `/api/tasks` - Create task
  - PUT `/api/tasks/:id` - Update task
  - DELETE `/api/tasks/:id` - Delete task

## Local Development

```bash
cd services
docker-compose up --build
```

Access: http://localhost:3000

## Environment Variables

Check `.env.example` files in each service directory.

## Database Schema

- **users:** id, username, password, created_at
- **tasks:** id, user_id, title, description, status, created_at, updated_at
