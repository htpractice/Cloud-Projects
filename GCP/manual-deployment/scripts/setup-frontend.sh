#!/bin/bash
# LookMyShow Frontend Setup Script (Presentation Tier)

set -e

echo "🎨 Setting up LookMyShow Frontend (Presentation Tier)..."
echo "==================================================="

# Get VM external IP
VM_EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo "YOUR_VM_EXTERNAL_IP")

echo "🌍 Detected VM External IP: $VM_EXTERNAL_IP"

# Check if frontend files exist
if [ ! -f "/var/www/html/lookmyshow/index.html" ]; then
    echo "❌ Frontend files not found in /var/www/html/lookmyshow/"
    echo "   Please copy the frontend files first:"
    echo "   sudo cp -r website/* /var/www/html/lookmyshow/"
    exit 1
fi

# Update script.js with VM IP
echo "🔧 Updating API URL in script.js..."
sudo sed -i "s/YOUR_VM_EXTERNAL_IP/$VM_EXTERNAL_IP/g" /var/www/html/lookmyshow/script.js

# Configure Nginx
echo "⚙️  Setting up Nginx configuration..."
sudo cp ../configs/nginx-lookmyshow.conf /etc/nginx/sites-available/lookmyshow

# Update nginx config with VM IP
sudo sed -i "s/YOUR_VM_EXTERNAL_IP/$VM_EXTERNAL_IP/g" /etc/nginx/sites-available/lookmyshow

# Enable the site
sudo ln -sf /etc/nginx/sites-available/lookmyshow /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration failed"
    exit 1
fi

# Restart Nginx
echo "🔄 Restarting Nginx..."
sudo systemctl restart nginx

# Check Nginx status
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx failed to start"
    sudo systemctl status nginx
    exit 1
fi

# Set proper permissions
echo "🔐 Setting proper file permissions..."
sudo chown -R www-data:www-data /var/www/html/lookmyshow
sudo chmod -R 755 /var/www/html/lookmyshow

# Test the website
echo "🧪 Testing website..."
sleep 2

if curl -s http://localhost/ | grep -q "LookMyShow"; then
    echo "✅ Website is accessible"
else
    echo "❌ Website test failed"
fi

echo ""
echo "✅ Frontend setup completed!"
echo ""
echo "🌍 Your LookMyShow website is now available at:"
echo "   http://$VM_EXTERNAL_IP"
echo ""
echo "🔗 Nginx Commands:"
echo "  sudo systemctl status nginx      # Check status"
echo "  sudo systemctl restart nginx    # Restart nginx"
echo "  sudo nginx -t                   # Test configuration"
echo ""
echo "📁 Website Files Location:"
echo "  /var/www/html/lookmyshow/"
echo ""
echo "📋 Quick Tests:"
echo "  curl http://localhost/                    # Test frontend"
echo "  curl http://localhost/api/health          # Test API via nginx"
echo "  curl http://localhost/api/events          # Test events API" 