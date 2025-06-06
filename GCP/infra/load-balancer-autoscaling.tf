# LookMyShow Load Balancer and Auto-scaling Infrastructure
# Complete 3-tier architecture with global load balancing and auto-scaling

# Instance Template for Auto-scaling
resource "google_compute_instance_template" "app_template" {
  name_prefix  = "lookmyshow-app-template-"
  machine_type = "e2-medium"
  region       = var.region

  # Boot disk
  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  # Network interface
  network_interface {
    network    = google_compute_network.lookmyshow_vpc.id
    subnetwork = google_compute_subnetwork.app_subnet.id
    
    access_config {
      # Ephemeral public IP
    }
  }

  # Service account
  service_account {
    email = google_service_account.cloudsql_proxy.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloudsql"
    ]
  }

  # Startup script to configure the application
  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    DB_CONNECTION_NAME = google_sql_database_instance.primary.connection_name
    DB_NAME           = google_sql_database.eventsdb.name
    DB_USER           = google_sql_user.app_user.name
    SECRET_NAME       = google_secret_manager_secret.db_password.secret_id
    PROJECT_ID        = var.project_id
    REGION           = var.region
  })

  # Tags for firewall rules
  tags = ["lookmyshow-app", "http-server", "https-server"]

  labels = {
    environment = var.environment
    application = "lookmyshow"
    tier        = "application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Managed Instance Group for Auto-scaling
resource "google_compute_region_instance_group_manager" "app_group" {
  name   = "lookmyshow-app-group"
  region = var.region

  version {
    instance_template = google_compute_instance_template.app_template.id
  }

  base_instance_name = "lookmyshow-app"
  target_size        = 3

  # Auto-healing
  auto_healing_policies {
    health_check      = google_compute_health_check.app_health_check.id
    initial_delay_sec = 300
  }

  # Update policy
  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
  }

  named_port {
    name = "http"
    port = 8080
  }
}

# Auto-scaler for the instance group
resource "google_compute_region_autoscaler" "app_autoscaler" {
  name   = "lookmyshow-app-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.app_group.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 10
    cooldown_period = 60

    # CPU utilization scaling
    cpu_utilization {
      target = 0.7
    }

    # Load balancer utilization scaling
    load_balancing_utilization {
      target = 0.8
    }

    # Scale-in control
    scale_in_control {
      max_scaled_in_replicas {
        fixed = 2
      }
      time_window_sec = 120
    }
  }
}

# Health check for load balancer
resource "google_compute_health_check" "app_health_check" {
  name                = "lookmyshow-app-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# Global HTTP(S) Load Balancer
# Backend service
resource "google_compute_backend_service" "app_backend" {
  name                  = "lookmyshow-app-backend"
  protocol              = "HTTP"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL"

  backend {
    group           = google_compute_region_instance_group_manager.app_group.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.app_health_check.id]

  # Connection draining
  connection_draining_timeout_sec = 30

  # Session affinity for stateful sessions
  session_affinity = "CLIENT_IP"

  # Cloud CDN configuration
  enable_cdn = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 7200

    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = false
    }
  }
}

# URL Map for routing
resource "google_compute_url_map" "app_url_map" {
  name            = "lookmyshow-url-map"
  default_service = google_compute_backend_service.app_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.app_backend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.app_backend.id
    }

    path_rule {
      paths   = ["/static/*"]
      service = google_compute_backend_service.app_backend.id
    }
  }
}

# HTTP(S) Proxy
resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "lookmyshow-http-proxy"
  url_map = google_compute_url_map.app_url_map.id
}

# Global forwarding rule (HTTP)
resource "google_compute_global_forwarding_rule" "app_http_forwarding_rule" {
  name       = "lookmyshow-http-forwarding-rule"
  target     = google_compute_target_http_proxy.app_http_proxy.id
  port_range = "80"
}

# Firewall rules
resource "google_compute_firewall" "allow_http" {
  name    = "lookmyshow-allow-http"
  network = google_compute_network.lookmyshow_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "lookmyshow-allow-https"
  network = google_compute_network.lookmyshow_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "lookmyshow-allow-health-check"
  network = google_compute_network.lookmyshow_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  # Google Cloud health check ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["lookmyshow-app"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "lookmyshow-allow-internal"
  network = google_compute_network.lookmyshow_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Additional monitoring for autoscaling
resource "google_monitoring_alert_policy" "high_cpu_utilization" {
  display_name = "LookMyShow High CPU Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "Instance group CPU utilization is high"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.labels.instance_name=~\"lookmyshow-app-.*\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      duration        = "300s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields = ["resource.labels.instance_name"]
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content = "Instance group CPU utilization is consistently high. Auto-scaler should be adding more instances."
  }
}

resource "google_monitoring_alert_policy" "load_balancer_error_rate" {
  display_name = "LookMyShow Load Balancer High Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Load balancer error rate is high"
    
    condition_threshold {
      filter          = "resource.type=\"http_load_balancer\" AND resource.labels.backend_service_name=\"${google_compute_backend_service.app_backend.name}\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.05  # 5% error rate
      duration        = "300s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}

# Outputs for load balancer
output "load_balancer_ip" {
  description = "Load balancer public IP address"
  value       = google_compute_global_forwarding_rule.app_http_forwarding_rule.ip_address
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = "http://${google_compute_global_forwarding_rule.app_http_forwarding_rule.ip_address}"
}

output "instance_group_manager" {
  description = "Instance group manager name"
  value       = google_compute_region_instance_group_manager.app_group.name
}

output "autoscaler_name" {
  description = "Autoscaler name"
  value       = google_compute_region_autoscaler.app_autoscaler.name
} 