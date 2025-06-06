#!/usr/bin/env python3
"""
Infrastructure deployment script for LookMyShow three-tier architecture
This script helps deploy the application to GCP
"""

import os
import sys
import subprocess
import json
from pathlib import Path

class GCPDeployer:
    def __init__(self):
        self.project_id = os.getenv('GCP_PROJECT_ID')
        self.region = os.getenv('GCP_REGION', 'us-central1')
        self.zone = os.getenv('GCP_ZONE', 'us-central1-a')
        
    def check_prerequisites(self):
        """Check if required tools are installed"""
        required_tools = ['gcloud', 'docker']
        missing_tools = []
        
        for tool in required_tools:
            try:
                subprocess.run([tool, '--version'], 
                             capture_output=True, check=True)
                print(f"✓ {tool} is installed")
            except (subprocess.CalledProcessError, FileNotFoundError):
                missing_tools.append(tool)
                print(f"✗ {tool} is not installed")
        
        if missing_tools:
            print(f"\nPlease install missing tools: {', '.join(missing_tools)}")
            return False
        
        return True
    
    def create_cloud_sql_instance(self):
        """Create Cloud SQL instance for data tier"""
        print("\n🗄️  Creating Cloud SQL instance...")
        
        instance_name = "lookmyshow-db"
        
        cmd = [
            'gcloud', 'sql', 'instances', 'create', instance_name,
            '--database-version=MYSQL_8_0',
            '--tier=db-f1-micro',
            '--region=' + self.region,
            '--storage-size=10GB',
            '--storage-type=SSD'
        ]
        
        try:
            subprocess.run(cmd, check=True)
            print(f"✓ Cloud SQL instance '{instance_name}' created")
            
            # Create database
            subprocess.run([
                'gcloud', 'sql', 'databases', 'create', 'eventsdb',
                '--instance=' + instance_name
            ], check=True)
            print("✓ Database 'eventsdb' created")
            
            return instance_name
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to create Cloud SQL instance: {e}")
            return None
    
    def deploy_app_engine(self):
        """Deploy application tier to App Engine"""
        print("\n🚀 Deploying to App Engine...")
        
        # Create app.yaml
        app_yaml_content = """
runtime: python39

env_variables:
  DB_HOST: "127.0.0.1"
  DB_USER: "root"
  DB_PASSWORD: "your-db-password"
  DB_NAME: "eventsdb"
  
automatic_scaling:
  min_instances: 1
  max_instances: 10
"""
        
        with open('../website/app.yaml', 'w') as f:
            f.write(app_yaml_content.strip())
        
        try:
            subprocess.run(['gcloud', 'app', 'deploy', '../website/app.yaml'], 
                         check=True, cwd=os.getcwd())
            print("✓ Application deployed to App Engine")
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to deploy to App Engine: {e}")
    
    def create_compute_engine_vm(self):
        """Create Compute Engine VM for presentation tier"""
        print("\n💻 Creating Compute Engine VM...")
        
        vm_name = "lookmyshow-frontend"
        
        startup_script = """#!/bin/bash
# Install nginx
apt-get update
apt-get install -y nginx

# Copy website files
mkdir -p /var/www/html/lookmyshow
# Note: You'll need to copy your HTML/CSS/JS files here

# Configure nginx
cat > /etc/nginx/sites-available/lookmyshow << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html/lookmyshow;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /api/ {
        proxy_pass http://your-app-engine-url/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/lookmyshow /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
"""
        
        cmd = [
            'gcloud', 'compute', 'instances', 'create', vm_name,
            '--zone=' + self.zone,
            '--machine-type=e2-micro',
            '--image-family=ubuntu-2004-lts',
            '--image-project=ubuntu-os-cloud',
            '--metadata=startup-script=' + startup_script,
            '--tags=http-server,https-server'
        ]
        
        try:
            subprocess.run(cmd, check=True)
            print(f"✓ VM '{vm_name}' created")
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to create VM: {e}")
    
    def setup_firewall_rules(self):
        """Setup firewall rules"""
        print("\n🔥 Setting up firewall rules...")
        
        rules = [
            {
                'name': 'allow-http',
                'direction': 'INGRESS',
                'action': 'allow',
                'rules': 'tcp:80',
                'target-tags': 'http-server'
            },
            {
                'name': 'allow-https',
                'direction': 'INGRESS',
                'action': 'allow',
                'rules': 'tcp:443',
                'target-tags': 'https-server'
            }
        ]
        
        for rule in rules:
            cmd = [
                'gcloud', 'compute', 'firewall-rules', 'create', rule['name'],
                '--direction=' + rule['direction'],
                '--action=' + rule['action'],
                '--rules=' + rule['rules'],
                '--target-tags=' + rule['target-tags']
            ]
            
            try:
                subprocess.run(cmd, check=True)
                print(f"✓ Firewall rule '{rule['name']}' created")
            except subprocess.CalledProcessError:
                print(f"⚠️  Firewall rule '{rule['name']}' might already exist")
    
    def print_deployment_summary(self):
        """Print deployment summary"""
        print("\n" + "="*50)
        print("🎉 DEPLOYMENT SUMMARY")
        print("="*50)
        print("\n📋 Three-Tier Architecture Deployed:")
        print("   1. 🎨 Presentation Tier: Compute Engine VM with Nginx")
        print("   2. 🔧 Application Tier: App Engine with Flask API")
        print("   3. 🗄️  Data Tier: Cloud SQL MySQL instance")
        print("\n📝 Next Steps:")
        print("   1. Update database credentials in app.yaml")
        print("   2. Copy frontend files to the VM")
        print("   3. Update API_BASE_URL in script.js")
        print("   4. Test the application")
        print("\n🔗 Useful Commands:")
        print("   gcloud app browse  # Open App Engine app")
        print("   gcloud compute instances list  # List VMs")
        print("   gcloud sql instances list  # List SQL instances")
    
    def deploy(self):
        """Main deployment function"""
        print("🚀 Starting LookMyShow Three-Tier Architecture Deployment")
        print("="*60)
        
        if not self.check_prerequisites():
            sys.exit(1)
        
        if not self.project_id:
            print("❌ Please set GCP_PROJECT_ID environment variable")
            sys.exit(1)
        
        print(f"📊 Project: {self.project_id}")
        print(f"🌍 Region: {self.region}")
        print(f"🏢 Zone: {self.zone}")
        
        # Deploy components
        self.setup_firewall_rules()
        self.create_cloud_sql_instance()
        self.deploy_app_engine()
        self.create_compute_engine_vm()
        
        self.print_deployment_summary()

if __name__ == "__main__":
    deployer = GCPDeployer()
    deployer.deploy() 