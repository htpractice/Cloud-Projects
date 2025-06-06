variable "zone" {
  description = "GCP zone for frontend VM"
  type        = string
  default     = "us-central1-a"
}

variable "website_bucket" {
  description = "GCS bucket containing the website static files (zip)"
  type        = string
  default     = "lookmyshow-website-static"
}

# LookMyShow Frontend VM (Presentation Tier)

resource "google_compute_instance" "frontend" {
  name         = "lookmyshow-frontend"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.lookmyshow_vpc.id
    subnetwork = google_compute_subnetwork.app_subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx unzip google-cloud-sdk
    mkdir -p /var/www/html/lookmyshow
    # Download and extract website static files from GCS
    gsutil cp gs://${var.website_bucket}/website.zip /tmp/website.zip
    unzip -o /tmp/website.zip -d /var/www/html/lookmyshow
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
            proxy_pass http://YOUR_APP_ENGINE_URL/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    EOF
    ln -s /etc/nginx/sites-available/lookmyshow /etc/nginx/sites-enabled/
    rm /etc/nginx/sites-enabled/default
    systemctl restart nginx
  EOT

  tags = ["http-server", "https-server"]

  labels = {
    environment = var.environment
    application = "lookmyshow"
    tier        = "frontend"
  }

  service_account {
    email  = google_service_account.cloudsql_proxy.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
} 