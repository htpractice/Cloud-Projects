# LookMyShow Three-Tier Architecture Deployment Guide

## 📋 Architecture Overview

### Three Tiers:
1. **🎨 Presentation Tier**: HTML/CSS/JavaScript frontend
2. **🔧 Application Tier**: Flask REST API with business logic  
3. **🗄️ Data Tier**: MySQL database with data access layer

## 🚀 Quick Deployment (One Command)

### Prerequisites
```bash
# Install Google Cloud SDK
# Set your project ID
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID
gcloud auth login
```

### Option 1: App Engine Deployment (Recommended)
```bash
cd GCP/website
gcloud app deploy app.yaml --quiet
```

### Option 2: Full Infrastructure Deployment
```bash
cd GCP/infra
python3 deploy.py
```

## 🔧 Manual Setup Steps

### 1. Database Setup (Data Tier)
```bash
# Connect to your existing MySQL instance
mysql -h 104.198.208.198 -u root -p

# Run the schema
source schema.sql
```

### 2. Application Tier Deployment
```bash
cd GCP/website

# Install dependencies
pip install -r requirements.txt

# Test locally first
python app.py

# Deploy to App Engine
gcloud app deploy app.yaml
```

### 3. Frontend Testing
```bash
# Open the deployed application
gcloud app browse
```

## 🧪 Testing the Three-Tier Architecture

### Test API Endpoints (Application Tier)
```bash
# Health check
curl https://your-app-url/api/health

# Get events
curl https://your-app-url/api/events

# Create booking
curl -X POST https://your-app-url/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"event_id": 1, "user_email": "test@example.com"}'

# Get bookings
curl https://your-app-url/api/bookings
```

### Test Database Connection (Data Tier)
```bash
# Connect to database
mysql -h 104.198.208.198 -u root -p eventsdb

# Verify data
SELECT * FROM events;
SELECT * FROM bookings;
```

## 📁 File Structure

```
GCP/
├── website/ (Application & Presentation Tiers)
│   ├── app.py              # Flask API (Application Tier)
│   ├── services.py         # Business Logic
│   ├── data_access.py      # Data Access Layer
│   ├── models.py           # Data Models (Data Tier)
│   ├── config.py           # Configuration
│   ├── index.html          # Frontend (Presentation Tier)
│   ├── script.js           # Frontend Logic
│   ├── styles.css          # Styling
│   ├── requirements.txt    # Python Dependencies
│   ├── app.yaml           # App Engine Config
│   └── schema.sql         # Database Schema
└── infra/
    └── deploy.py          # Infrastructure Automation
```

## 🔄 Architecture Flow

```
User Request → Presentation Tier (HTML/JS) 
           ↓
           → Application Tier (Flask API)
           ↓
           → Data Tier (MySQL Database)
```

## 🛠️ Environment Variables

The application uses these environment variables (already configured in app.yaml):

```yaml
DB_HOST: "104.198.208.198"
DB_USER: "root"
DB_PASSWORD: "M7rk|(`J&H1+*I>i"
DB_NAME: "eventsdb"
API_HOST: "0.0.0.0"
API_PORT: "8080"
CORS_ORIGINS: "*"
```

## 🚦 Verification Checklist

- [ ] Database connection works
- [ ] API endpoints respond correctly
- [ ] Frontend loads and displays events
- [ ] Booking functionality works
- [ ] Three-tier separation is maintained
- [ ] Error handling works properly

## 🔍 Troubleshooting

### Database Connection Issues
```bash
# Test database connectivity
mysql -h 104.198.208.198 -u root -p eventsdb -e "SELECT 1"
```

### API Issues
```bash
# Check logs
gcloud app logs tail

# Test API locally
cd GCP/website
python app.py
```

### Frontend Issues
- Check browser console for JavaScript errors
- Verify API_BASE_URL is correct in script.js
- Ensure CORS is properly configured

## 📊 Performance Monitoring

```bash
# Monitor App Engine metrics
gcloud app operations list

# View application logs
gcloud app logs read
```

## 🎯 Success Criteria

Your three-tier architecture is successfully deployed when:

1. ✅ **Presentation Tier**: Frontend displays events and handles user interactions
2. ✅ **Application Tier**: API responds to all endpoints with proper data
3. ✅ **Data Tier**: Database stores and retrieves data correctly
4. ✅ **Integration**: All tiers communicate seamlessly
5. ✅ **Scalability**: Application can handle multiple concurrent users

## 📞 Quick Commands Reference

```bash
# Deploy
gcloud app deploy

# View logs
gcloud app logs tail

# Open application
gcloud app browse

# Connect to database
mysql -h 104.198.208.198 -u root -p eventsdb
```

**Your LookMyShow three-tier architecture is now ready for submission! 🎉** 