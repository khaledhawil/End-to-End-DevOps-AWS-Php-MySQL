# Separated Nginx Service Documentation

## Overview

The application now uses a **separate nginx service** as the main entry point, acting as a reverse proxy for all backend services and the frontend. This architectural improvement provides better separation of concerns, easier scaling, and cleaner configuration management.

## Architecture

```
                    ┌─────────────────┐
                    │   Nginx Proxy   │
                    │   (Port 80)     │
                    └────────┬────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
    ┌───────▼──────┐ ┌──────▼──────┐ ┌────▼────────┐
    │  Frontend    │ │ Auth Service│ │Task Service │
    │  (Port 80)   │ │ (Port 8001) │ │(Port 8002)  │
    │  Internal    │ │             │ │             │
    └──────────────┘ └─────┬───────┘ └─────┬───────┘
                            │               │
                            └───────┬───────┘
                                    │
                            ┌───────▼───────┐
                            │     MySQL     │
                            │  (Port 3306)  │
                            └───────────────┘
```

## Key Changes

### 1. Nginx Service Configuration

**Location**: `services/nginx/`

- **nginx.conf**: Reverse proxy configuration with routing rules for all services
- **Dockerfile**: Lightweight Alpine-based nginx container

### 2. Docker Compose Updates

**Changes in docker-compose.yml**:
- ✅ Added new `nginx` service
- ✅ Removed external port mapping from frontend (3000:80)
- ✅ Nginx now exposes port 80 as the main entry point
- ✅ Frontend only accessible through nginx proxy

### 3. Routing Rules

The nginx proxy handles routing based on URL paths:

| Request Path | Proxied To | Service |
|--------------|------------|---------|
| `/` | `frontend:80` | React Frontend |
| `/api/auth/*` | `auth-service:8001` | Authentication API |
| `/api/tasks/*` | `task-service:8002` | Task Management API |

## Configuration Details

### Nginx Proxy Features

1. **Reverse Proxy**: Routes requests to appropriate backend services
2. **CORS Handling**: Adds CORS headers with credentials support
3. **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
4. **Gzip Compression**: Enabled for text/json/javascript files
5. **OPTIONS Handling**: Proper preflight request handling for CORS
6. **Logging**: Access and error logs for debugging

### Location Blocks

```nginx
# Auth Service API - handles all /api/auth/* requests
location ~ ^/api/auth($|/) {
    proxy_pass http://auth-service:8001;
    # ... headers and CORS ...
}

# Task Service API - handles all /api/tasks/* requests
location ~ ^/api/tasks($|/) {
    proxy_pass http://task-service:8002;
    # ... headers and CORS ...
}

# Frontend - catches all other requests
location / {
    proxy_pass http://frontend:80;
    # ... SPA routing support ...
}
```

## Access Points

### For Users
- **Main Application**: http://localhost/
- **All API calls go through nginx automatically**

### For Debugging (Direct Service Access)
- Auth Service: http://localhost:8001
- Task Service: http://localhost:8002
- MySQL: localhost:3306
- Frontend: Not exposed (internal only)

## Deployment Commands

### Start All Services
```bash
cd services
docker-compose up -d --build
```

### Rebuild Only Nginx
```bash
docker-compose up -d --build nginx
```

### View Nginx Logs
```bash
docker logs services-nginx-1
```

### Test Nginx Configuration
```bash
docker exec services-nginx-1 nginx -t
```

### Restart Nginx
```bash
docker-compose restart nginx
```

## Testing

A comprehensive test script is available:

```bash
cd services
chmod +x test-nginx-proxy.sh
./test-nginx-proxy.sh
```

**Test Coverage**:
- ✅ Frontend accessibility
- ✅ User registration through nginx
- ✅ User login through nginx
- ✅ Task creation through nginx
- ✅ Task retrieval through nginx
- ✅ Task status toggle through nginx
- ✅ Direct service health checks

## Benefits of Separated Nginx

### 1. **Better Separation of Concerns**
- Frontend container focuses only on serving React app
- Nginx container handles all routing and load balancing

### 2. **Easier Scaling**
```bash
# Scale frontend instances
docker-compose up -d --scale frontend=3
# Nginx automatically load balances
```

### 3. **Simplified Configuration**
- Single nginx.conf for all routing rules
- Easy to add new services or modify routes
- No changes needed to frontend or backend

### 4. **Production-Ready**
- Standard architecture used in enterprise applications
- Easy to replace with external load balancers (AWS ALB, etc.)
- SSL/TLS termination can be added at nginx layer

### 5. **Better Security**
- Single entry point for all traffic
- Backend services not directly exposed
- Easy to add rate limiting, IP filtering, etc.

## Maintenance

### Adding a New Service

1. Add service to `docker-compose.yml`:
```yaml
new-service:
  build: ./new-service
  depends_on:
    - mysql
```

2. Add routing in `nginx/nginx.conf`:
```nginx
location /api/newservice/ {
    proxy_pass http://new-service:PORT;
    # ... proxy headers ...
}
```

3. Rebuild:
```bash
docker-compose up -d --build
```

### Updating Nginx Configuration

1. Edit `services/nginx/nginx.conf`
2. Test configuration:
```bash
docker exec services-nginx-1 nginx -t
```
3. Reload if valid:
```bash
docker-compose restart nginx
```

## Troubleshooting

### 1. API Requests Return 404
**Cause**: URL path mismatch between nginx and backend service  
**Solution**: Check that location blocks match actual service routes

### 2. CORS Errors
**Cause**: Missing or incorrect CORS headers  
**Solution**: Verify `Access-Control-Allow-*` headers in nginx.conf

### 3. Nginx Won't Start
**Cause**: Configuration syntax error  
**Solution**: 
```bash
docker exec services-nginx-1 nginx -t
docker logs services-nginx-1
```

### 4. Backend Service Unreachable
**Cause**: Service not running or wrong hostname  
**Solution**: 
```bash
docker ps  # Check all services are running
docker network inspect services_default  # Verify network
```

## Performance Considerations

### Connection Pooling
Nginx maintains persistent connections to backend services using HTTP/1.1

### Caching (Future Enhancement)
Can add nginx caching for static assets:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
proxy_cache my_cache;
```

### Load Balancing (Future Enhancement)
Can add upstream blocks for horizontal scaling:
```nginx
upstream frontend_backend {
    server frontend:80;
    server frontend-2:80;
    server frontend-3:80;
}
```

## Monitoring

### Key Metrics to Monitor
- Request rate (requests/second)
- Response times (p50, p95, p99)
- Error rates (4xx, 5xx)
- Active connections
- Upstream health

### Access Logs
```bash
docker exec services-nginx-1 tail -f /var/log/nginx/access.log
```

### Error Logs
```bash
docker exec services-nginx-1 tail -f /var/log/nginx/error.log
```

## Security Hardening

### Current Security Features
- ✅ X-Frame-Options: SAMEORIGIN
- ✅ X-Content-Type-Options: nosniff
- ✅ X-XSS-Protection: 1; mode=block
- ✅ Referrer-Policy: no-referrer-when-downgrade

### Future Enhancements
- [ ] SSL/TLS certificates (Let's Encrypt)
- [ ] Rate limiting per IP
- [ ] Request size limits
- [ ] IP whitelisting/blacklisting
- [ ] ModSecurity WAF integration

## Conclusion

The separated nginx service provides a robust, scalable, and maintainable architecture. All services communicate through Docker's internal network, with nginx as the single public-facing entry point on port 80.

**Key Takeaway**: Access everything through `http://localhost/` - nginx handles all the routing! 🚀
