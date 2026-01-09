# Application Build Guide and Architecture

## Table of Contents
1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Technology Stack](#technology-stack)
4. [Service Communication](#service-communication)
5. [Build Instructions](#build-instructions)
6. [Deployment Options](#deployment-options)

---

## Overview

This is a task management system built using a microservices architecture. The application allows users to register, login, manage tasks, and logout. It is containerized using Docker and can be deployed either locally with Docker Compose or to AWS cloud infrastructure using Kubernetes (EKS).

### Application Purpose
- User authentication (register/login)
- Task creation and management
- Task completion tracking
- User session management

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT BROWSER                          │
│                     (http://localhost:8080)                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               │ HTTP Request
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX REVERSE PROXY                          │
│                    (Port 8080 -> 80)                            │
│                                                                 │
│  Routes requests to appropriate microservices                  │
└──────────────┬──────────────────┬──────────────────┬───────────┘
               │                  │                  │
               │                  │                  │
    ┌──────────▼──────┐  ┌───────▼────────┐  ┌──────▼────────┐
    │   FRONTEND      │  │  USERS SERVICE │  │ LOGOUT SERVICE│
    │   SERVICE       │  │                │  │               │
    │                 │  │  - Login       │  │  - Logout     │
    │  - Main UI      │  │  - Register    │  │  - Session    │
    │  - Task List    │  │  - Dashboard   │  │    Clear      │
    │  - Add Task     │  │  - Add Task    │  │               │
    │  - Delete Task  │  │  - Delete Task │  │               │
    │                 │  │                │  │               │
    │  Port: 80       │  │  Port: 80      │  │  Port: 80     │
    └────────┬────────┘  └────────┬───────┘  └───────────────┘
             │                    │
             │                    │
             └──────────┬─────────┘
                        │
                        │ Database Connection
                        │ (Host: db, Port: 3306)
                        │
                        ▼
           ┌─────────────────────────┐
           │    MYSQL DATABASE       │
           │                         │
           │  - Database: task_manager│
           │  - Tables:              │
           │    * users              │
           │    * tasks              │
           │                         │
           │  Port: 3306             │
           └─────────────────────────┘
```

---

## Technology Stack

### 1. Docker
**Purpose:** Containerization platform that packages applications with their dependencies.

**Why It's Important:**
- Ensures consistency across development, testing, and production environments
- Isolates each service in its own container
- Makes the application portable across different operating systems
- Simplifies dependency management

**In This Project:**
- Each service (Frontend, Users, Logout) runs in its own container
- MySQL database runs in a separate container
- Nginx reverse proxy runs in its own container

### 2. Docker Compose
**Purpose:** Tool for defining and running multi-container Docker applications.

**Why It's Important:**
- Orchestrates multiple containers as a single application
- Manages networking between containers
- Handles container startup order and dependencies
- Simplifies development environment setup

**In This Project:**
- Defined in `task-management-system/compose.yml`
- Creates a shared network for all services
- Ensures database is healthy before starting dependent services
- Maps port 8080 on host to port 80 in nginx container

### 3. PHP 8.2 with Apache
**Purpose:** Server-side programming language and web server.

**Why It's Important:**
- Handles business logic and database operations
- Processes user authentication
- Generates dynamic HTML content
- Manages sessions and cookies

**In This Project:**
- All three application services use PHP 8.2 with Apache
- PHP PDO extension connects to MySQL database
- Apache serves PHP files and handles HTTP requests

### 4. MySQL 5.7
**Purpose:** Relational database management system.

**Why It's Important:**
- Stores persistent data (users, tasks)
- Provides ACID compliance for data integrity
- Supports complex queries and relationships
- Handles concurrent user access

**In This Project:**
- Stores user credentials (hashed passwords)
- Stores task information with user relationships
- Provides data persistence across container restarts
- Uses volume mounting for data durability

### 5. Nginx
**Purpose:** High-performance web server and reverse proxy.

**Why It's Important:**
- Acts as a single entry point for all client requests
- Routes requests to appropriate backend services
- Handles load balancing
- Provides SSL termination capability
- Improves security by hiding internal service structure

**In This Project:**
- Listens on port 8080 (host) and 80 (container)
- Routes `/` to frontend service
- Routes `/pages/login.php`, `/pages/register.php` to users service
- Routes `/pages/logout.php` to logout service
- Serves static files (CSS, JS)

### 6. Kubernetes (EKS)
**Purpose:** Container orchestration platform for production deployments.

**Why It's Important:**
- Automates deployment, scaling, and management
- Provides self-healing capabilities
- Manages rolling updates with zero downtime
- Handles service discovery and load balancing

**In This Project:**
- Used for AWS production deployment
- Manages containerized services at scale
- Integrates with AWS Elastic Container Registry (ECR)
- Uses Ingress controller for external access

### 7. Terraform
**Purpose:** Infrastructure as Code (IaC) tool.

**Why It's Important:**
- Automates cloud infrastructure provisioning
- Ensures reproducible infrastructure
- Version controls infrastructure changes
- Manages dependencies between resources

**In This Project:**
- Provisions AWS EKS cluster
- Creates ECR repositories
- Sets up VPC networking
- Configures RDS MySQL database
- Manages security groups and IAM roles

---

## Service Communication

### 1. Client to Nginx Reverse Proxy

**Flow:**
```
Browser → http://localhost:8080 → Nginx Container (Port 80)
```

**Details:**
- Client sends HTTP request to port 8080
- Docker port mapping forwards to nginx container port 80
- Nginx examines the request path to determine routing

### 2. Nginx to Application Services

**Flow:**
```
Nginx → Frontend Service (Port 80)
Nginx → Users Service (Port 80)
Nginx → Logout Service (Port 80)
```

**Details:**
- All services are on the same Docker network: `app-network`
- Nginx uses container names for routing:
  - `http://frontend:80` for frontend service
  - `http://users-service:80` for users service
  - `http://logout-service:80` for logout service
- Docker's internal DNS resolves container names to IP addresses

**Nginx Configuration Example:**
```nginx
location /pages/login.php {
    proxy_pass http://users-service:80;
}

location /pages/logout.php {
    proxy_pass http://logout-service:80;
}

location / {
    proxy_pass http://frontend:80;
}
```

### 3. Application Services to MySQL Database

**Flow:**
```
Users Service → MySQL Container (Port 3306)
Frontend Service → MySQL Container (Port 3306)
```

**Connection Details:**
- Services use environment variables for database connection:
  - `DB_HOST=db` (container name)
  - `DB_USER=root`
  - `DB_PASS=password`
  - `DB_DATABASE=task_manager`
  - `DB_PORT=3306`

**PHP PDO Connection Example:**
```php
$dsn = "mysql:host=db;port=3306;dbname=task_manager;charset=utf8mb4";
$conn = new PDO($dsn, $username, $password);
```

**Why Container Name Works:**
- Docker Compose creates a custom bridge network
- All services on this network can communicate using container names
- Docker's embedded DNS server resolves `db` to MySQL container's IP

### 4. Database Initialization

**Flow:**
```
MySQL Startup → Execute init-db.sql → Create tables and schema
```

**Details:**
- `init-db.sql` is mounted to `/docker-entrypoint-initdb.d/`
- MySQL executes all SQL files in this directory on first startup
- Creates `users` and `tasks` tables
- Only runs on initial database creation

### 5. Health Check Mechanism

**Flow:**
```
Docker → MySQL Health Check → Users Service Starts
```

**Details:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "mysql -h 'localhost' -u 'root' -p'password' -e 'SELECT 1'"]
  timeout: 20s
  retries: 10
  interval: 10s
```

- Docker executes MySQL command every 10 seconds
- Users service waits for healthy status before starting
- Prevents connection errors during startup

---

## Build Instructions

### Local Development with Docker Compose

#### Prerequisites
- Docker Engine 20.10+
- Docker Compose 1.29+
- 4GB RAM minimum
- 10GB disk space

#### Step 1: Navigate to Project Directory
```bash
cd task-management-system
```

#### Step 2: Build Docker Images
```bash
docker-compose build --no-cache
```

**What Happens:**
1. Reads `compose.yml` file
2. Builds three custom images:
   - Frontend service from `frontend.Dockerfile`
   - Users service from `users.Dockerfile`
   - Logout service from `logout.Dockerfile`
3. Installs PHP extensions (PDO, pdo_mysql, mysqli)
4. Installs Composer dependencies
5. Configures Apache web server
6. Pulls MySQL 5.7 and Nginx images from Docker Hub

**Time:** 2-5 minutes depending on internet speed

#### Step 3: Start All Services
```bash
docker-compose up -d
```

**What Happens:**
1. Creates Docker network: `task-management-system_app-network`
2. Creates Docker volume: `task-management-system_db_data`
3. Starts MySQL container
4. Waits for MySQL health check to pass
5. Starts application services (frontend, users, logout)
6. Starts Nginx reverse proxy
7. All services run in detached mode (background)

**Time:** 30-60 seconds

#### Step 4: Verify Services are Running
```bash
docker-compose ps
```

**Expected Output:**
```
       Name                     Command                  State                              Ports                       
------------------------------------------------------------------------------------------------------------------------
frontend-container   docker-php-entrypoint apac ...   Up             80/tcp                                             
logout-container     docker-php-entrypoint apac ...   Up             80/tcp                                             
mysql-container      docker-entrypoint.sh mysqld      Up (healthy)   0.0.0.0:3306->3306/tcp,:::3306->3306/tcp, 33060/tcp
reverse-proxy        /docker-entrypoint.sh ngin ...   Up             0.0.0.0:8080->80/tcp,:::8080->80/tcp               
users-container      docker-php-entrypoint apac ...   Up             80/tcp
```

#### Step 5: Access Application
Open browser and navigate to:
```
http://localhost:8080
```

#### Step 6: Test Application Features

1. **Register New User:**
   - Navigate to registration page
   - Enter username and password
   - Submit form
   - User data stored in MySQL `users` table

2. **Login:**
   - Navigate to login page
   - Enter credentials
   - Session created and stored in PHP

3. **Add Task:**
   - After login, navigate to dashboard
   - Add new task with description and due date
   - Task stored in MySQL `tasks` table

4. **Complete/Delete Task:**
   - Mark task as complete
   - Delete task from list

5. **Logout:**
   - Click logout
   - Session destroyed
   - Redirected to login page

#### Troubleshooting Commands

**View Container Logs:**
```bash
docker-compose logs [service-name]
docker-compose logs users-service
docker-compose logs db
```

**Check Database Connection:**
```bash
docker exec mysql-container mysql -u root -ppassword -e "USE task_manager; SHOW TABLES;"
```

**Restart Services:**
```bash
docker-compose restart
```

**Stop All Services:**
```bash
docker-compose down
```

**Stop and Remove All Data:**
```bash
docker-compose down -v
```

---

## Deployment Options

### Option 1: Local Development (Docker Compose)

**Best For:**
- Development and testing
- Learning and experimentation
- Single developer environments

**Advantages:**
- Quick setup (5 minutes)
- Easy debugging
- No cloud costs
- Full control over environment

**Command:**
```bash
cd task-management-system
docker-compose up -d
```

### Option 2: AWS Cloud Deployment (Kubernetes + EKS)

**Best For:**
- Production environments
- High availability requirements
- Scalable applications
- Team collaboration

**Prerequisites:**
- AWS account
- AWS CLI configured
- Terraform 1.0+
- kubectl
- Docker
- Helm

**Step 1: Configure AWS Credentials**
```bash
aws configure
# Enter AWS Access Key ID
# Enter AWS Secret Access Key
# Enter default region (e.g., us-east-1)
```

**Step 2: Verify Setup**
```bash
./run_me_first.sh
```

**What Happens:**
- Checks if AWS CLI is installed
- Verifies AWS credentials are configured
- Displays AWS account ID and region

**Step 3: Review and Update Variables**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Update these values:**
```hcl
project_name        = "your-project-name"
region              = "us-east-1"
environment         = "dev"
db_username         = "admin"
db_password         = "your-secure-password"
```

**Step 4: Deploy Infrastructure and Application**
```bash
cd ..
./build.sh
```

**What Happens (30-45 minutes):**

1. **Terraform Initialization:**
   - Downloads AWS provider plugins
   - Initializes backend state

2. **Infrastructure Provisioning:**
   - Creates VPC with public/private/database subnets across 2 availability zones
   - Sets up Internet Gateway and NAT Gateway
   - Configures Security Groups
   - Creates EKS cluster with managed node groups
   - Provisions RDS MySQL instance
   - Creates 3 ECR repositories (frontend, users, logout)
   - Sets up AWS Secrets Manager for database credentials
   - Installs monitoring stack (Prometheus, Grafana, Alertmanager)
   - Configures AWS Load Balancer Controller

3. **Docker Image Building:**
   - Builds frontend service image
   - Builds users service image
   - Builds logout service image
   - Tags images with ECR repository URLs

4. **ECR Image Push:**
   - Authenticates to ECR
   - Pushes all three images to respective repositories

5. **Database Setup:**
   - Retrieves RDS endpoint from Terraform output
   - Connects to MySQL database
   - Executes init-db.sql schema

6. **Kubernetes Deployment:**
   - Updates kubeconfig for EKS cluster
   - Deploys frontend service with deployment and service
   - Deploys users service with deployment and service
   - Deploys logout service with deployment and service
   - Creates database initialization job
   - Configures Ingress for external access

7. **Final Steps:**
   - Retrieves Load Balancer DNS name
   - Displays application URL

**Step 5: Access Application**
```bash
# Get Load Balancer URL
kubectl get ingress -n default

# Output will show DNS hostname
# Example: a1b2c3d4e5f6-1234567890.us-east-1.elb.amazonaws.com
```

**Step 6: Monitor Application**
```bash
# View pods
kubectl get pods

# View services
kubectl get svc

# View logs
kubectl logs -f deployment/frontend-service
```

**Step 7: Cleanup (When Done)**
```bash
./destroy.sh
```

**What Happens:**
- Deletes Kubernetes resources
- Removes ECR repositories and images
- Destroys EKS cluster
- Removes RDS database
- Deletes VPC and networking components
- Cleans up all AWS resources

**Estimated Monthly AWS Costs:**
- EKS Cluster: $73/month
- EC2 Instances (3x t3.medium): $75/month
- RDS MySQL (db.t3.medium): $115/month
- VPC NAT Gateway: $33/month
- Load Balancer: $20/month
- ECR Storage: $1/month
- Data Transfer: $10-20/month
- **Total: ~$350-400/month**

---

## Container Interactions Summary

### Network Layer
```
app-network (Docker Bridge Network)
    │
    ├── reverse-proxy (nginx)
    ├── frontend-container
    ├── users-container
    ├── logout-container
    └── mysql-container
```

### Data Flow for User Login

1. **Client Request:**
   ```
   Browser → http://localhost:8080/pages/login.php
   ```

2. **Nginx Routing:**
   ```
   Nginx receives request on port 8080
   Examines URL path: /pages/login.php
   Routes to users-service:80 via internal network
   ```

3. **Users Service Processing:**
   ```
   Apache receives request on port 80
   PHP executes login.php
   Includes database.php for connection
   ```

4. **Database Query:**
   ```
   PHP PDO connects to mysql://db:3306/task_manager
   Executes: SELECT * FROM users WHERE username = ?
   Retrieves user record
   Verifies password hash
   ```

5. **Session Creation:**
   ```
   PHP creates session
   Sets session cookie
   Redirects to dashboard.php
   ```

6. **Response:**
   ```
   Users Service → Nginx → Client Browser
   Browser stores session cookie
   Redirects to dashboard
   ```

### Data Persistence

**Volume Mounting:**
```yaml
volumes:
  - db_data:/var/lib/mysql
```

**Purpose:**
- MySQL data persists across container restarts
- Data stored on host filesystem
- Survives `docker-compose down` (unless using `-v` flag)

**Location:**
- Linux: `/var/lib/docker/volumes/task-management-system_db_data/`
- macOS: Docker VM internal storage
- Windows: Docker Desktop WSL2 storage

---

## Security Considerations

### 1. Database Credentials
- Stored in environment variables
- Should use Docker secrets in production
- AWS deployment uses Secrets Manager

### 2. Password Hashing
- User passwords hashed using PHP `password_hash()`
- Uses bcrypt algorithm
- Never stores plaintext passwords

### 3. Network Isolation
- Services communicate only within Docker network
- Only nginx is exposed externally
- Database not directly accessible from outside

### 4. HTTPS/SSL
- Local deployment uses HTTP
- Production should use HTTPS
- AWS deployment can use AWS Certificate Manager

---

## Development Workflow

### Making Code Changes

1. **Modify PHP files:**
   ```bash
   nano task-management-system/pages/dashboard.php
   ```

2. **Rebuild affected service:**
   ```bash
   docker-compose build users-service
   ```

3. **Restart service:**
   ```bash
   docker-compose up -d users-service
   ```

4. **View changes immediately** in browser

### Database Changes

1. **Modify init-db.sql:**
   ```bash
   nano task-management-system/init-db.sql
   ```

2. **Recreate database:**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

**Warning:** This deletes all data

### Configuration Changes

1. **Modify compose.yml or nginx.conf**
2. **Restart affected services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

---

## Monitoring and Logs

### View All Logs
```bash
docker-compose logs -f
```

### View Specific Service
```bash
docker-compose logs -f users-service
```

### View Last 100 Lines
```bash
docker-compose logs --tail=100 users-service
```

### Check Container Resource Usage
```bash
docker stats
```

### Execute Commands Inside Container
```bash
docker exec -it users-container bash
```

---

## Conclusion

This application demonstrates a complete microservices architecture with:
- Service separation and isolation
- Reverse proxy routing
- Database persistence
- Container orchestration
- Infrastructure as code
- Cloud deployment capabilities

The modular design allows for:
- Independent service scaling
- Easy maintenance and updates
- Clear separation of concerns
- Flexible deployment options
