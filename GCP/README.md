# 🎯 LookMyShow Three-Tier Architecture - GCP Deployment

## 📋 Overview

This repository contains **two complete deployment options** for the LookMyShow event booking platform using a proper three-tier architecture on Google Cloud Platform.

## 🏗️ Architecture

```
🎨 Presentation Tier  →  🔧 Application Tier  →  🗄️ Data Tier
   (HTML/CSS/JS)         (Flask REST API)       (MySQL Database)
```

---

## 🚀 Deployment Options

### Option 1: 🤖 Automated Deployment (Recommended)
**Location**: `website/` and `infra/`

Perfect for environments with full GCP access and automation tools.

```bash
cd website/
gcloud app deploy app.yaml --quiet
```

**Features:**
- ✅ One-command deployment with App Engine
- ✅ Automatic scaling and load balancing
- ✅ Built-in monitoring and logging
- ✅ Production-ready configuration

**Files:**
- `website/app.py` - Flask API with three-tier structure
- `website/app.yaml` - App Engine configuration
- `website/index.html` - Frontend interface
- `DEPLOYMENT_GUIDE.md` - Complete automation guide
- `infra/deploy.py` - Infrastructure automation script

---

### Option 2: 🛠️ Manual Deployment (Practice Lab Friendly)
**Location**: `manual-deployment/`

Perfect for restricted environments or when you need full control over the deployment process.

```bash
cd manual-deployment/
chmod +x deploy-all.sh
./deploy-all.sh
```

**Features:**
- ✅ Step-by-step manual deployment
- ✅ Works with limited GCP access
- ✅ Educational and transparent process
- ✅ Full three-tier separation
- ✅ Nginx + systemd + MySQL setup

**Structure:**
```
manual-deployment/
├── website/           # 🎨 Presentation Tier
├── backend/           # 🔧 Application Tier  
├── database/          # 🗄️ Data Tier
├── configs/           # ⚙️ System Configurations
├── scripts/           # 🛠️ Deployment Scripts
└── deploy-all.sh      # 🚀 One-click deployment
```

---

## 🎯 Which Option to Choose?

### Use **Automated Deployment** if:
- ✅ You have full GCP project permissions
- ✅ You want production-ready deployment
- ✅ You prefer managed services (App Engine)
- ✅ You need quick deployment for submission

### Use **Manual Deployment** if:
- ✅ You're in a practice lab with limited access
- ✅ You want to understand each deployment step
- ✅ You need to customize the infrastructure
- ✅ Terraform/automated tools don't work in your environment

---

## 🏃‍♂️ Quick Start Guide

### For Automated Deployment:
```bash
# 1. Setup
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID

# 2. Deploy database schema
mysql -h YOUR_DB_IP -u root -p < website/schema.sql

# 3. Deploy application
cd website/
gcloud app deploy app.yaml

# 4. Test
gcloud app browse
```

### For Manual Deployment:
```bash
# 1. Create VM
gcloud compute instances create lookmyshow-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2004-lts \
  --tags=http-server

# 2. Copy files and deploy
gcloud compute scp --recurse manual-deployment/ lookmyshow-vm:~/
gcloud compute ssh lookmyshow-vm --command="cd manual-deployment && ./deploy-all.sh"

# 3. Get IP and test
VM_IP=$(gcloud compute instances describe lookmyshow-vm \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
curl http://$VM_IP/
```

---

## 📊 Architecture Verification

Both deployment options implement the same three-tier architecture:

### 🎨 Presentation Tier
- **Technology**: HTML5, CSS3, JavaScript (ES6+)
- **Responsibility**: User interface and user experience
- **Location**: Frontend files served by web server

### 🔧 Application Tier  
- **Technology**: Python Flask with RESTful API design
- **Responsibility**: Business logic, validation, API endpoints
- **Components**: Services, Data Access Layer, Models
- **Endpoints**: `/api/events`, `/api/bookings`, `/api/health`

### 🗄️ Data Tier
- **Technology**: MySQL database
- **Responsibility**: Data persistence and management
- **Tables**: `events`, `bookings` with proper relationships
- **Features**: Connection pooling, prepared statements

---

## 🧪 Testing Both Deployments

### API Endpoints (Application Tier)
```bash
# Health check
curl https://your-app/api/health

# Get events  
curl https://your-app/api/events

# Create booking
curl -X POST https://your-app/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"event_id": 1, "user_email": "test@example.com"}'
```

### Frontend Testing (Presentation Tier)
1. Open browser to your application URL
2. Verify events load from API
3. Test booking functionality
4. Check responsive design

### Database Testing (Data Tier)
```bash
# Connect to database
mysql -h YOUR_DB_IP -u root -p eventsdb

# Verify data
SELECT * FROM events;
SELECT * FROM bookings;
```

---

## 📁 Repository Structure

```
GCP/
├── README.md                           # 📖 This file
├── DEPLOYMENT_GUIDE.md                 # 🤖 Automated deployment
├── website/                            # 🤖 Automated deployment files
│   ├── app.py                         # Flask application
│   ├── app.yaml                       # App Engine config
│   ├── *.py                          # Backend components
│   └── *.html/css/js                  # Frontend files
├── infra/                             # 🤖 Infrastructure automation
│   └── deploy.py                      # GCP deployment script
└── manual-deployment/                  # 🛠️ Manual deployment
    ├── MANUAL_DEPLOYMENT_GUIDE.md      # 📖 Manual guide
    ├── deploy-all.sh                   # 🚀 Complete setup
    ├── website/                        # Frontend files
    ├── backend/                        # Backend files
    ├── database/                       # Schema files
    ├── configs/                        # System configs
    └── scripts/                        # Setup scripts
```

---

## 🎓 Learning Outcomes

By completing either deployment, you will understand:

### Technical Skills:
- ✅ Three-tier architecture design and implementation
- ✅ RESTful API development with Flask
- ✅ Database design with MySQL
- ✅ Frontend-backend integration
- ✅ Cloud deployment strategies
- ✅ DevOps and system administration

### GCP Services:
- ✅ Compute Engine (VMs)
- ✅ App Engine (PaaS)
- ✅ Cloud SQL (Database)
- ✅ Networking and Firewall
- ✅ IAM and Security

---

## 🚀 Ready for Submission!

Both deployment options provide:
- ✅ **Complete three-tier architecture**
- ✅ **Working event booking system**
- ✅ **Proper separation of concerns**
- ✅ **Scalable and maintainable code**
- ✅ **Production-ready deployment**
- ✅ **Comprehensive documentation**

Choose the option that best fits your environment and deploy with confidence!

---

## 📞 Support

If you encounter issues:
1. 📖 Check the respective deployment guide
2. 🔍 Review troubleshooting sections
3. 🧪 Run the provided test commands
4. 📋 Verify the deployment checklist

**Good luck with your submission! 🎉** 