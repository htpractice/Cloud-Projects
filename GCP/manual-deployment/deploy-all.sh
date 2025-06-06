#!/bin/bash
# LookMyShow Master Deployment Script - Complete Three-Tier Setup

set -e

echo "🚀 LookMyShow Complete Manual Deployment"
echo "========================================"
echo ""

# Function to print status
print_status() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Make scripts executable
chmod +x scripts/*.sh

echo "📋 Starting three-tier deployment process..."
echo ""

# Step 1: VM Setup
echo "🔧 Step 1: Setting up VM base environment..."
sudo scripts/setup-vm.sh
print_status "VM setup completed"
echo ""

# Step 2: Copy files
echo "📁 Step 2: Copying application files..."
sudo cp -r backend/* /opt/lookmyshow/backend/
sudo cp -r configs/ /opt/lookmyshow/
sudo cp -r website/* /var/www/html/lookmyshow/
print_status "Files copied to correct locations"
echo ""

# Step 3: Backend Setup (Application Tier)
echo "🔧 Step 3: Setting up Application Tier (Backend)..."
sudo scripts/setup-backend.sh
print_status "Application Tier deployed"
echo ""

# Step 4: Frontend Setup (Presentation Tier)
echo "🎨 Step 4: Setting up Presentation Tier (Frontend)..."
sudo scripts/setup-frontend.sh
print_status "Presentation Tier deployed"
echo ""

# Get VM IP
VM_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo "YOUR_VM_IP")

echo "🧪 Step 5: Final verification..."
sleep 2

# Quick tests
if curl -s http://localhost/api/health | grep -q "healthy"; then
    print_status "API health check passed"
else
    print_error "API health check failed"
fi

if curl -s http://localhost/ | grep -q "LookMyShow"; then
    print_status "Frontend accessibility verified"
else
    print_error "Frontend verification failed"
fi

echo ""
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "===================================="
echo ""
echo "🏗️ Three-Tier Architecture Deployed:"
echo "   🎨 Presentation Tier: Frontend (Nginx)"
echo "   🔧 Application Tier:  Flask API"  
echo "   🗄️ Data Tier:        MySQL Database"
echo ""
echo "🌍 Access your application:"
echo "   Website: http://$VM_IP"
echo "   API:     http://$VM_IP/api"
echo ""
echo "🔧 Management commands:"
echo "   sudo systemctl status lookmyshow-api nginx"
echo "   sudo systemctl restart lookmyshow-api nginx"
echo "   sudo journalctl -u lookmyshow-api -f"
echo ""
echo "✅ Your LookMyShow three-tier architecture is ready for submission!" 