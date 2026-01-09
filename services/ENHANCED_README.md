# Task Manager - Microservices Architecture

Modern task management application built with microservices architecture with enhanced features and robust error handling.

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Frontend  │────▶ │   Nginx      │────▶ │  Auth API   │
│  (React +   │      │  (Reverse    │      │  (Node.js)  │
│   Vite)     │      │   Proxy)     │      └─────────────┘
└─────────────┘      └──────────────┘              │
                              │                    │
                              │                    ▼
                              │            ┌─────────────┐
                              │            │   MySQL     │
                              │            │  Database   │
                              ▼            └─────────────┘
                     ┌─────────────┐              ▲
                     │   Task API  │              │
                     │   (Flask)   │──────────────┘
                     └─────────────┘
```

## 🚀 Quick Start

### Start All Services
```bash
cd services/
docker-compose up -d
```

### Access Application
- **Frontend**: http://localhost:3000
- **Auth API**: http://localhost:8001
- **Task API**: http://localhost:8002

### Check Status
```bash
docker-compose ps
curl http://localhost:8001/health
curl http://localhost:8002/health
```

## 📦 Services Overview

### Frontend (React + Vite)
- **Port**: 3000
- **Features**:
  - User authentication (login/register)
  - Task CRUD operations with real-time updates
  - Task priority levels (low, medium, high)
  - Task status toggling (pending/completed)
  - Inline task editing
  - Responsive modern UI
  - Loading states and comprehensive error handling
  - Browser console debugging enabled

### Auth Service (Node.js + Express)
- **Port**: 8001
- **Endpoints**:
  - `POST /api/auth/register` - User registration
  - `POST /api/auth/login` - User login (returns JWT)
  - `POST /api/auth/verify` - Verify JWT token
  - `GET /api/auth/profile` - Get user profile
  - `GET /health` - Health check
- **Features**:
  - JWT authentication (24h expiration)
  - bcrypt password hashing
  - Enhanced CORS with credentials support
  - Request/response logging
  - Error handling middleware

### Task Service (Python + Flask)
- **Port**: 8002
- **Endpoints**:
  - `GET /api/tasks` - Get all user tasks
  - `POST /api/tasks` - Create new task
  - `PUT /api/tasks/:id` - Update task
  - `DELETE /api/tasks/:id` - Delete task
  - `PATCH /api/tasks/:id/status` - Toggle task status
  - `GET /health` - Health check
- **Features**:
  - JWT authentication middleware
  - Task priorities and status management
  - Comprehensive logging
  - MySQL connection pooling
  - Proper CORS configuration

### Database (MySQL 8.0)
- **Port**: 3306
- **Schema**:
  - Users table with authentication data
  - Tasks table with priorities, status, and timestamps
  - Optimized indexes for performance
  - Foreign key constraints

## 🔧 Configuration

### Environment Variables

Create `.env` files or use docker-compose environment section:

**Auth Service**:
```env
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=password
DB_NAME=task_manager
JWT_SECRET=dev-secret-key
PORT=8001
```

**Task Service**:
```env
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=password
DB_NAME=task_manager
JWT_SECRET=dev-secret-key
PORT=8002
```

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username)
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    status ENUM('pending', 'completed') DEFAULT 'pending',
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_tasks (user_id, created_at),
    INDEX idx_user_status (user_id, status),
    INDEX idx_user_priority (user_id, priority)
);
```

## 🔄 Database Migration

If updating an existing database:

```bash
# Using the helper script
./migrate-db.sh

# Or manually
docker exec -i $(docker ps -qf "name=mysql") mysql -uroot -ppassword task_manager < migrate-db.sql
```

## 🛠️ Local Development

### Frontend Development
```bash
cd frontend/
npm install
npm run dev  # Runs on http://localhost:5173
```

### Auth Service Development
```bash
cd auth-service/
npm install
npm run dev  # Runs on http://localhost:8001
```

### Task Service Development
```bash
cd task-service/
pip install -r requirements.txt
python app.py  # Runs on http://localhost:8002
```

## 🔍 Troubleshooting

### Issue: Tasks Not Saving

**Solution 1: Check Logs**
```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs task-service
docker-compose logs auth-service
```

**Solution 2: Verify Token**
- Open browser DevTools → Console
- Check for any error messages
- Verify token is in localStorage
- Check Network tab for API call responses

**Solution 3: Test Backend Directly**
```bash
# Register
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'

# Login and get token
TOKEN=$(curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}' | jq -r '.token')

# Create task
curl -X POST http://localhost:8002/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test","description":"Test task","priority":"high"}'
```

### Issue: Database Connection Failed

**Solution**:
```bash
# Restart MySQL and wait for it to be healthy
docker-compose restart mysql
sleep 15
docker-compose restart auth-service task-service
```

### Issue: CORS Errors

Both services now have enhanced CORS support. If issues persist:
1. Clear browser cache
2. Check browser console for specific CORS error
3. Verify nginx.conf proxy settings

## 🧪 API Testing Examples

### Register User
```bash
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"secure123"}'
```

### Login
```bash
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"secure123"}'
```

### Get Profile
```bash
curl http://localhost:8001/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Task
```bash
curl -X POST http://localhost:8002/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"Learn Docker","description":"Complete Docker tutorial","priority":"high"}'
```

### Get Tasks
```bash
curl http://localhost:8002/api/tasks \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Toggle Task Status
```bash
curl -X PATCH http://localhost:8002/api/tasks/1/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📝 Nginx Configuration

Located in `frontend/nginx.conf`:
- Reverse proxy for API requests
- React Router fallback support
- Gzip compression enabled
- Proper header forwarding

## 🐳 Docker Commands

```bash
# Start all services
docker-compose up -d

# Start with logs visible
docker-compose up

# Rebuild and start
docker-compose up -d --build

# View logs
docker-compose logs -f
docker-compose logs -f task-service

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v

# Restart specific service
docker-compose restart frontend
```

## ✨ Recent Enhancements

### Backend Improvements
- ✅ Enhanced CORS configuration with credentials support
- ✅ Comprehensive request/response logging
- ✅ Better error handling and error messages
- ✅ JWT token verification improvements
- ✅ Task priority support (low, medium, high)
- ✅ Task status toggle endpoint
- ✅ User profile endpoint
- ✅ Database connection pooling
- ✅ Optimized database indexes

### Frontend Improvements
- ✅ Loading states for all operations
- ✅ Better error handling and display
- ✅ Task editing functionality
- ✅ Task status toggling
- ✅ Priority indicators with color coding
- ✅ Responsive grid layout
- ✅ Modern UI with gradients and animations
- ✅ Console logging for debugging
- ✅ Session expiration handling
- ✅ Confirmation dialogs for destructive actions

## 🎨 UI Features

- Modern gradient-based color scheme
- Priority-based color coding (red=high, orange=medium, blue=low)
- Status badges (completed/pending)
- Hover effects and smooth transitions
- Responsive design (mobile-friendly)
- Loading indicators
- Error messages with clear styling
- Confirmation dialogs

## 📚 File Structure

```
services/
├── auth-service/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js           # Enhanced with logging & CORS
├── task-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py             # Enhanced with logging & features
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf         # Reverse proxy configuration
│   ├── package.json
│   └── src/
│       ├── App.css        # Enhanced styles
│       ├── App.jsx
│       └── pages/
│           ├── Dashboard.jsx  # Enhanced with features
│           ├── Login.jsx
│           └── Register.jsx
├── docker-compose.yml     # Service orchestration
├── init-db.sql           # Initial schema
├── migrate-db.sql        # Migration script
└── migrate-db.sh         # Migration helper
```

## 🔮 Future Enhancements

- [ ] Task due dates with visual indicators
- [ ] Task categories/tags
- [ ] Task filtering and sorting
- [ ] Task search functionality
- [ ] User avatars
- [ ] Task sharing between users
- [ ] Email notifications
- [ ] Dark mode toggle
- [ ] Export tasks (CSV, JSON)
- [ ] Task statistics dashboard
- [ ] Drag-and-drop task reordering
- [ ] Rich text editor for descriptions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests.

## 📄 License

MIT License - Free to use for learning and development.

---

**Need Help?** Check the logs first: `docker-compose logs -f`
