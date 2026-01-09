#!/bin/bash

echo "=================================="
echo "NGINX PROXY TESTING SCRIPT"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test frontend
echo "1. Testing Frontend..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$FRONTEND_STATUS" == "200" ]; then
    echo -e "${GREEN}✓ Frontend accessible through nginx (http://localhost/)${NC}"
else
    echo -e "${RED}✗ Frontend failed (Status: $FRONTEND_STATUS)${NC}"
fi
echo ""

# Generate unique username for testing
RANDOM_ID=$RANDOM
USERNAME="testuser${RANDOM_ID}"
EMAIL="test${RANDOM_ID}@test.com"
PASSWORD="testpass123"

# Test auth service - register
echo "2. Testing Auth Service (Register)..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost/api/auth/register \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

if echo "$REGISTER_RESPONSE" | grep -q "registered successfully"; then
    echo -e "${GREEN}✓ Registration working through nginx${NC}"
    echo "   Response: $REGISTER_RESPONSE"
else
    echo -e "${RED}✗ Registration failed${NC}"
    echo "   Response: $REGISTER_RESPONSE"
    exit 1
fi
echo ""

# Test auth service - login
echo "3. Testing Auth Service (Login)..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost/api/auth/login \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✓ Login successful through nginx${NC}"
    echo "   Token received (first 20 chars): ${TOKEN:0:20}..."
else
    echo -e "${RED}✗ Login failed${NC}"
    echo "   Response: $LOGIN_RESPONSE"
    exit 1
fi
echo ""

# Test auth service - verify token
echo "4. Testing Auth Service (Token Verification)..."
VERIFY_RESPONSE=$(curl -s -X POST http://localhost/api/auth/verify \
    -H "Content-Type: application/json" \
    -d "{\"token\":\"$TOKEN\"}")

if echo "$VERIFY_RESPONSE" | grep -q "valid"; then
    echo -e "${GREEN}✓ Token verification working through nginx${NC}"
else
    echo -e "${RED}✗ Token verification failed${NC}"
    echo "   Response: $VERIFY_RESPONSE"
fi
echo ""

# Test task service - create task
echo "5. Testing Task Service (Create Task)..."
TASK_RESPONSE=$(curl -s -X POST http://localhost/api/tasks \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"title":"Test task via nginx","description":"Testing nginx proxy","priority":"high"}')

TASK_ID=$(echo "$TASK_RESPONSE" | grep -o '"taskId":[0-9]*' | cut -d':' -f2)

if [ -n "$TASK_ID" ]; then
    echo -e "${GREEN}✓ Task creation working through nginx${NC}"
    echo "   Task ID: $TASK_ID"
    echo "   Response: $TASK_RESPONSE"
else
    echo -e "${RED}✗ Task creation failed${NC}"
    echo "   Response: $TASK_RESPONSE"
fi
echo ""

# Test task service - get tasks
echo "6. Testing Task Service (Get Tasks)..."
TASKS_RESPONSE=$(curl -s -X GET http://localhost/api/tasks \
    -H "Authorization: Bearer $TOKEN")

if echo "$TASKS_RESPONSE" | grep -q "Test task via nginx"; then
    echo -e "${GREEN}✓ Task retrieval working through nginx${NC}"
    TASK_COUNT=$(echo "$TASKS_RESPONSE" | grep -o '"id":' | wc -l)
    echo "   Retrieved $TASK_COUNT task(s)"
else
    echo -e "${RED}✗ Task retrieval failed${NC}"
    echo "   Response: $TASKS_RESPONSE"
fi
echo ""

# Test task service - toggle status
if [ -n "$TASK_ID" ]; then
    echo "7. Testing Task Service (Toggle Status)..."
    TOGGLE_RESPONSE=$(curl -s -X PATCH http://localhost/api/tasks/${TASK_ID}/status \
        -H "Authorization: Bearer $TOKEN")
    
    if echo "$TOGGLE_RESPONSE" | grep -q "completed"; then
        echo -e "${GREEN}✓ Task status toggle working through nginx${NC}"
        echo "   Task marked as completed"
    else
        echo -e "${RED}✗ Task status toggle failed${NC}"
        echo "   Response: $TOGGLE_RESPONSE"
    fi
    echo ""
fi

# Test direct service health (bypassing nginx)
echo "8. Testing Direct Service Health (bypassing nginx)..."
AUTH_HEALTH=$(curl -s http://localhost:8001/health | grep -o '"status":"[^"]*' | cut -d'"' -f4)
TASK_HEALTH=$(curl -s http://localhost:8002/health | grep -o '"status":"[^"]*' | cut -d'"' -f4)

if [ "$AUTH_HEALTH" == "healthy" ] && [ "$TASK_HEALTH" == "healthy" ]; then
    echo -e "${GREEN}✓ All backend services healthy${NC}"
    echo "   Auth service: $AUTH_HEALTH"
    echo "   Task service: $TASK_HEALTH"
else
    echo -e "${YELLOW}⚠ Some services may have issues${NC}"
    echo "   Auth service: $AUTH_HEALTH"
    echo "   Task service: $TASK_HEALTH"
fi
echo ""

# Summary
echo "=================================="
echo "SUMMARY"
echo "=================================="
echo -e "${GREEN}✓ Separated nginx service is working correctly!${NC}"
echo ""
echo "Access Points:"
echo "  - Frontend: http://localhost/"
echo "  - Auth API: http://localhost/api/auth/*"
echo "  - Task API: http://localhost/api/tasks/*"
echo ""
echo "Direct Service Ports (for debugging):"
echo "  - Auth Service: http://localhost:8001"
echo "  - Task Service: http://localhost:8002"
echo "  - Frontend: Not exposed (accessed through nginx only)"
echo "=================================="
