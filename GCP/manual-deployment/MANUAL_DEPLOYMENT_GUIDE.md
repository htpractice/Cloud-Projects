# 🚀 LookMyShow Manual Three-Tier Deployment Guide

## 📋 Overview

This guide provides **step-by-step manual deployment** instructions for the LookMyShow three-tier architecture on Google Cloud Platform. Use this when automated deployment tools are not available or restricted.

### 🏗️ Architecture Components:
1. **🎨 Presentation Tier**: Nginx serving HTML/CSS/JS
2. **🔧 Application Tier**: Flask API running as systemd service  
3. **🗄️ Data Tier**: MySQL database (existing instance)

---

## 📁 File Structure

```
manual-deployment/
├── website/           # 🎨 Presentation Tier Files
│   ├── index.html
│   ├── script.js
│   └── styles.css
├── backend/           # 🔧 Application Tier Files  
│   ├── app.py
│   ├── config.py
│   ├── models.py
│   ├── data_access.py
│   ├── services.py
│   └── requirements.txt
├── database/          # 🗄️ Data Tier Files
│   └── schema.sql
├── configs/           # ⚙️ Configuration Files
│   ├── nginx-lookmyshow.conf
│   └── lookmyshow-api.service
├── scripts/           # 🛠️ Deployment Scripts
│   ├── setup-vm.sh
│   ├── setup-backend.sh
│   └── setup-frontend.sh
└── MANUAL_DEPLOYMENT_GUIDE.md
```

---

## 🚀 Step-by-Step Deployment

### Step 1: Create VM Instance

```bash
# Create a VM instance on GCP
gcloud compute instances create lookmyshow-vm \
    --zone=us-central1-a \
    --machine-type=e2-medium \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=20GB \
    --tags=http-server,https-server

# Get external IP
gcloud compute instances describe lookmyshow-vm \
    --zone=us-central1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Step 2: Setup Database (Data Tier)

```bash
# Connect to your existing MySQL instance
mysql -h 104.198.208.198 -u root -p

# Run the schema file
mysql> source database/schema.sql

# Verify setup
mysql> USE eventsdb;
mysql> SHOW TABLES;
mysql> SELECT * FROM events;
```

### Step 3: Setup VM Base Environment

```bash
# SSH into your VM
gcloud compute ssh lookmyshow-vm --zone=us-central1-a

# Copy files to VM (from your local machine)
gcloud compute scp --recurse manual-deployment/ lookmyshow-vm:~/ --zone=us-central1-a

# On the VM, run base setup
cd manual-deployment/scripts
chmod +x *.sh
sudo ./setup-vm.sh
```

### Step 4: Deploy Backend (Application Tier)

```bash
# Copy backend files
sudo cp -r ../backend/* /opt/lookmyshow/backend/
sudo cp -r ../configs/ /opt/lookmyshow/

# Update database configuration
sudo nano /opt/lookmyshow/backend/config.py
# Verify database connection details are correct

# Run backend setup
sudo ./setup-backend.sh

# Verify backend is running
sudo systemctl status lookmyshow-api
curl http://localhost:5000/api/health
```

### Step 5: Deploy Frontend (Presentation Tier)

```bash
# Copy frontend files
sudo cp -r ../website/* /var/www/html/lookmyshow/

# Run frontend setup
sudo ./setup-frontend.sh

# Test the complete application
curl http://localhost/
curl http://localhost/api/health
curl http://localhost/api/events
```

---

## 🔧 Configuration Updates

### Update Database Connection

Edit `/opt/lookmyshow/backend/config.py`:

```python
DATABASE_CONFIG = DatabaseConfig(
    host="YOUR_DB_IP",        # Update with your DB IP
    user="your_db_user",      # Update with your DB user
    password="your_password", # Update with your DB password
    database="eventsdb"
)
```

### Update Frontend API URL

The setup script automatically updates `script.js`, but you can manually edit:

```javascript
// In /var/www/html/lookmyshow/script.js
const VM_IP = 'YOUR_VM_EXTERNAL_IP';  // Your VM's external IP
```

---

## 🧪 Testing & Verification

### Test Each Tier

```bash
# 🗄️ Test Data Tier
mysql -h YOUR_DB_IP -u root -p eventsdb -e "SELECT COUNT(*) FROM events;"

# 🔧 Test Application Tier
curl http://localhost:5000/api/health
curl http://localhost:5000/api/events
curl -X POST http://localhost:5000/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"event_id": 1, "user_email": "test@example.com"}'

# 🎨 Test Presentation Tier
curl http://localhost/
curl http://localhost/api/health  # Via nginx proxy
```

### Test Complete Integration

1. **Open browser**: `http://YOUR_VM_EXTERNAL_IP`
2. **Verify events load**: Should show list of events
3. **Test booking**: Click "Book Now" and enter email
4. **Check bookings**: Should appear in bookings section

---

## 🔍 Troubleshooting

### Backend Issues

```bash
# Check service status
sudo systemctl status lookmyshow-api

# View logs
sudo journalctl -u lookmyshow-api -f

# Restart service
sudo systemctl restart lookmyshow-api

# Test database connection
cd /opt/lookmyshow/backend
sudo -u www-data /opt/lookmyshow/venv/bin/python -c "
from config import DATABASE_CONFIG
import mysql.connector
mysql.connector.connect(**DATABASE_CONFIG.__dict__)
print('Database connection OK')
"
```

### Frontend Issues

```bash
# Check nginx status
sudo systemctl status nginx

# Test nginx config
sudo nginx -t

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

### Database Issues

```bash
# Test database connectivity
mysql -h YOUR_DB_IP -u root -p eventsdb -e "SELECT 1"

# Check if tables exist
mysql -h YOUR_DB_IP -u root -p eventsdb -e "SHOW TABLES"

# Re-run schema if needed
mysql -h YOUR_DB_IP -u root -p < database/schema.sql
```

### Network Issues

```bash
# Check firewall rules
sudo ufw status

# Test local connectivity
curl http://localhost:5000/api/health
curl http://localhost/

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(80|5000)'

# Test external connectivity
curl http://YOUR_VM_EXTERNAL_IP/api/health
```

---

## 📊 Service Management

### Backend Service Commands

```bash
sudo systemctl start lookmyshow-api      # Start service
sudo systemctl stop lookmyshow-api       # Stop service  
sudo systemctl restart lookmyshow-api    # Restart service
sudo systemctl enable lookmyshow-api     # Enable auto-start
sudo systemctl disable lookmyshow-api    # Disable auto-start
sudo systemctl status lookmyshow-api     # Check status
sudo journalctl -u lookmyshow-api        # View logs
```

### Nginx Commands

```bash
sudo systemctl start nginx               # Start nginx
sudo systemctl stop nginx                # Stop nginx
sudo systemctl restart nginx             # Restart nginx
sudo systemctl reload nginx              # Reload config
sudo nginx -t                           # Test config
sudo nginx -s reload                    # Reload gracefully
```

---

## 🔐 Security Considerations

### Firewall Configuration

```bash
# Basic firewall rules (already configured by setup script)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### File Permissions

```bash
# Ensure proper ownership
sudo chown -R www-data:www-data /opt/lookmyshow
sudo chown -R www-data:www-data /var/www/html/lookmyshow

# Set appropriate permissions
sudo chmod -R 755 /var/www/html/lookmyshow
sudo chmod 600 /opt/lookmyshow/backend/config.py  # Protect sensitive config
```

---

## 📈 Performance Optimization

### Nginx Optimization

```bash
# Edit nginx config for better performance
sudo nano /etc/nginx/sites-available/lookmyshow

# Add these optimizations:
# - Gzip compression (already included)
# - Static file caching (already included)  
# - Connection keep-alive
# - Worker processes optimization
```

### Database Optimization

```sql
-- Add indexes for better performance (already in schema.sql)
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_bookings_user_email ON bookings(user_email);
```

---

## 🚀 Deployment Verification Checklist

- [ ] ✅ VM created and accessible
- [ ] ✅ Database schema loaded and accessible
- [ ] ✅ Backend service running and responding
- [ ] ✅ Frontend serving via nginx
- [ ] ✅ API endpoints working through nginx proxy
- [ ] ✅ Events loading on website
- [ ] ✅ Booking functionality working
- [ ] ✅ All three tiers communicating properly
- [ ] ✅ Firewall rules configured
- [ ] ✅ Services enabled for auto-start

---

## 📞 Quick Reference Commands

```bash
# 🔍 Check Everything
sudo systemctl status lookmyshow-api nginx
curl http://localhost/api/health
curl http://YOUR_VM_EXTERNAL_IP/

# 🔄 Restart Everything  
sudo systemctl restart lookmyshow-api nginx

# 📋 View All Logs
sudo journalctl -u lookmyshow-api -f &
sudo tail -f /var/log/nginx/error.log

# 🧪 Test Complete Stack
curl http://localhost:5000/api/events    # Direct API
curl http://localhost/api/events         # Via nginx
curl http://YOUR_VM_EXTERNAL_IP/         # External access
```

---

## 🎯 Success Criteria

Your manual deployment is successful when:

1. **🎨 Presentation Tier**: Website loads at `http://YOUR_VM_IP`
2. **🔧 Application Tier**: API responds at `http://YOUR_VM_IP/api/health`
3. **🗄️ Data Tier**: Database queries return event data
4. **🔄 Integration**: Full booking workflow functions end-to-end
5. **📊 Monitoring**: All services running and logs are clean

---

**🎉 Congratulations! Your LookMyShow three-tier architecture is now manually deployed and running!**

For any issues, refer to the troubleshooting section above or check the service logs for detailed error information. 