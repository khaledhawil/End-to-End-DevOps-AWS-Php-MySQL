#!/bin/bash
# Quick Start Script for Task Manager Application

echo "🚀 Task Manager - Quick Start"
echo "=============================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install it first."
    exit 1
fi

echo "✅ docker-compose is available"
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down -v > /dev/null 2>&1

echo "📦 Building and starting services..."
docker-compose up -d --build

echo ""
echo "⏳ Waiting for services to start..."
sleep 5

# Wait for MySQL to be healthy
echo "⏳ Waiting for MySQL to initialize (this may take 20-30 seconds)..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose ps | grep mysql | grep -q "Up (healthy)"; then
        echo "✅ MySQL is ready!"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo -n "."
done
echo ""

if [ $elapsed -ge $timeout ]; then
    echo "⚠️  MySQL is taking longer than expected. Checking status..."
    docker-compose ps
fi

sleep 5

echo ""
echo "🔍 Checking service health..."
echo ""

# Check auth service
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ Auth Service (port 8001): Running"
else
    echo "❌ Auth Service (port 8001): Not responding"
fi

# Check task service
if curl -s http://localhost:8002/health > /dev/null 2>&1; then
    echo "✅ Task Service (port 8002): Running"
else
    echo "❌ Task Service (port 8002): Not responding"
fi

# Check frontend
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend (port 3000): Running"
else
    echo "❌ Frontend (port 3000): Not responding"
fi

echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "=============================="
echo "🎉 Setup Complete!"
echo "=============================="
echo ""
echo "📱 Access the application:"
echo "   Frontend:  http://localhost:3000"
echo "   Auth API:  http://localhost:8001"
echo "   Task API:  http://localhost:8002"
echo ""
echo "📚 Useful commands:"
echo "   View logs:           docker-compose logs -f"
echo "   View specific logs:  docker-compose logs -f task-service"
echo "   Stop services:       docker-compose down"
echo "   Restart services:    docker-compose restart"
echo ""
echo "🐛 Debugging:"
echo "   - Check browser console (F12) for errors"
echo "   - Check service logs: docker-compose logs -f"
echo "   - Test API: curl http://localhost:8001/health"
echo ""
echo "📖 Documentation:"
echo "   - ENHANCED_README.md - Full documentation"
echo "   - FIXES_SUMMARY.md   - What was fixed and enhanced"
echo ""
echo "Happy task managing! 🎯"
