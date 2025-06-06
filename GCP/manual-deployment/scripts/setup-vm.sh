#!/bin/bash
# LookMyShow VM Setup Script for Manual Three-Tier Deployment
# This script sets up a VM for hosting the presentation and application tiers

set -e

echo "🚀 Starting LookMyShow VM Setup..."
echo "================================"

# Update system
echo "📦 Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt-get install -y \
    nginx \
    python3 \
    python3-pip \
    python3-venv \
    mysql-client \
    git \
    curl \
    ufw \
    tree

# Create application directory structure
echo "📁 Creating directory structure..."
sudo mkdir -p /opt/lookmyshow/{backend,logs}
sudo mkdir -p /var/www/html/lookmyshow

# Set proper ownership
sudo chown -R www-data:www-data /opt/lookmyshow
sudo chown -R www-data:www-data /var/www/html/lookmyshow

# Setup Python virtual environment
echo "🐍 Setting up Python virtual environment..."
sudo -u www-data python3 -m venv /opt/lookmyshow/venv
sudo -u www-data /opt/lookmyshow/venv/bin/pip install --upgrade pip

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5000/tcp  # For direct API access during testing
sudo ufw --force enable

# Create log directories
echo "📝 Setting up logging..."
sudo mkdir -p /var/log/lookmyshow
sudo chown www-data:www-data /var/log/lookmyshow

echo "✅ VM setup completed!"
echo ""
echo "🔍 System Information:"
echo "  - OS: $(lsb_release -d | cut -f2)"
echo "  - Python: $(python3 --version)"
echo "  - Nginx: $(nginx -v 2>&1)"
echo "  - MySQL Client: $(mysql --version)"
echo ""
echo "📂 Directory Structure:"
tree /opt/lookmyshow/ || echo "/opt/lookmyshow/ created"
echo ""
echo "🎯 Next Steps:"
echo "  1. Copy backend files to /opt/lookmyshow/backend/"
echo "  2. Copy frontend files to /var/www/html/lookmyshow/"
echo "  3. Run setup-backend.sh"
echo "  4. Run setup-frontend.sh" 