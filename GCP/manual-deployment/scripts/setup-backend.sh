#!/bin/bash
# LookMyShow Backend Setup Script (Application Tier)

set -e

echo "🔧 Setting up LookMyShow Backend (Application Tier)..."
echo "================================================"

# Check if backend files exist
if [ ! -f "/opt/lookmyshow/backend/app.py" ]; then
    echo "❌ Backend files not found in /opt/lookmyshow/backend/"
    echo "   Please copy the backend files first:"
    echo "   sudo cp -r backend/* /opt/lookmyshow/backend/"
    exit 1
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
sudo -u www-data /opt/lookmyshow/venv/bin/pip install -r /opt/lookmyshow/backend/requirements.txt

# Test database connection
echo "🗄️  Testing database connection..."
cd /opt/lookmyshow/backend
sudo -u www-data /opt/lookmyshow/venv/bin/python -c "
import mysql.connector
from config import DATABASE_CONFIG
try:
    conn = mysql.connector.connect(
        host=DATABASE_CONFIG.host,
        user=DATABASE_CONFIG.user,
        password=DATABASE_CONFIG.password,
        database=DATABASE_CONFIG.database
    )
    print('✅ Database connection successful!')
    conn.close()
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
"

# Copy systemd service file
echo "⚙️  Setting up systemd service..."
sudo cp ../configs/lookmyshow-api.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start and enable the service
echo "🚀 Starting LookMyShow API service..."
sudo systemctl enable lookmyshow-api
sudo systemctl start lookmyshow-api

# Check service status
sleep 3
if sudo systemctl is-active --quiet lookmyshow-api; then
    echo "✅ LookMyShow API service is running!"
else
    echo "❌ Service failed to start. Checking logs..."
    sudo journalctl -u lookmyshow-api --no-pager -l
    exit 1
fi

# Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 2

# Test health endpoint
if curl -s http://localhost:5000/api/health | grep -q "healthy"; then
    echo "✅ Health endpoint working"
else
    echo "❌ Health endpoint failed"
fi

# Test events endpoint
if curl -s http://localhost:5000/api/events | grep -q "\["; then
    echo "✅ Events endpoint working"
else
    echo "❌ Events endpoint failed"
fi

echo ""
echo "✅ Backend setup completed!"
echo ""
echo "🔗 Service Commands:"
echo "  sudo systemctl status lookmyshow-api   # Check status"
echo "  sudo systemctl restart lookmyshow-api  # Restart service"
echo "  sudo journalctl -u lookmyshow-api      # View logs"
echo ""
echo "🧪 Test URLs:"
echo "  curl http://localhost:5000/api/health"
echo "  curl http://localhost:5000/api/events" 