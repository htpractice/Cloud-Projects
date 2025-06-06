# LookMyShow Database Scaling Infrastructure
# Enhanced 3-tier architecture with Cloud SQL HA, Read Replicas, and Disaster Recovery

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Primary GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "prod"
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Random password for database
resource "random_password" "mysql_password" {
  length  = 32
  special = true
}

# VPC Network for private communication
resource "google_compute_network" "lookmyshow_vpc" {
  name                    = "lookmyshow-vpc"
  auto_create_subnetworks = false
}

# Subnet for the application
resource "google_compute_subnetwork" "app_subnet" {
  name          = "lookmyshow-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.lookmyshow_vpc.id
}

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "lookmyshow-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.lookmyshow_vpc.id
}

# Private connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.lookmyshow_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Primary Instance with High Availability
resource "google_sql_database_instance" "primary" {
  name             = "lookmyshow-mysql-primary"
  database_version = "MYSQL_8_0"
  region           = var.region
  
  settings {
    tier                        = "db-n1-standard-2"
    availability_type          = "REGIONAL"  # High availability
    disk_type                  = "PD_SSD"
    disk_size                  = 100
    disk_autoresize           = true
    disk_autoresize_limit     = 500
    
    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"  # 3 AM UTC
      point_in_time_recovery_enabled = true
      binary_log_enabled            = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # Performance settings
    database_flags {
      name  = "innodb_buffer_pool_size"
      value = "75%"
    }
    
    database_flags {
      name  = "max_connections"
      value = "1000"
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.lookmyshow_vpc.id
      
      authorized_networks {
        name  = "app-subnet"
        value = "10.0.1.0/24"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 4  # 4 AM UTC
      update_track = "stable"
    }

    # Insights and monitoring
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = {
      environment = var.environment
      application = "lookmyshow"
      tier        = "database"
      role        = "primary"
    }
  }

  deletion_protection = true
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Read Replica in us-east1 for read scaling
resource "google_sql_database_instance" "read_replica_east" {
  name                 = "lookmyshow-mysql-replica-east"
  master_instance_name = google_sql_database_instance.primary.name
  region               = "us-east1"
  database_version     = "MYSQL_8_0"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier                = "db-n1-standard-1"
    availability_type   = "ZONAL"
    disk_type          = "PD_SSD"
    disk_size          = 100
    disk_autoresize    = true

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.lookmyshow_vpc.id
    }

    database_flags {
      name  = "read_only"
      value = "on"
    }

    user_labels = {
      environment = var.environment
      application = "lookmyshow"
      tier        = "database"
      role        = "read-replica"
      region      = "us-east1"
    }
  }

  deletion_protection = true
}

# Read Replica in europe-west1 for global read scaling
resource "google_sql_database_instance" "read_replica_europe" {
  name                 = "lookmyshow-mysql-replica-europe"
  master_instance_name = google_sql_database_instance.primary.name
  region               = "europe-west1"
  database_version     = "MYSQL_8_0"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier                = "db-n1-standard-1"
    availability_type   = "ZONAL"
    disk_type          = "PD_SSD"
    disk_size          = 100
    disk_autoresize    = true

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.lookmyshow_vpc.id
    }

    database_flags {
      name  = "read_only"
      value = "on"
    }

    user_labels = {
      environment = var.environment
      application = "lookmyshow"
      tier        = "database"
      role        = "read-replica"
      region      = "europe-west1"
    }
  }

  deletion_protection = true
}

# Database and user setup
resource "google_sql_database" "eventsdb" {
  name     = "eventsdb"
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_user" "app_user" {
  name     = "lookmyshow_app"
  instance = google_sql_database_instance.primary.name
  password = random_password.mysql_password.result
  host     = "%"
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "lookmyshow-db-password"

  labels = {
    environment = var.environment
    application = "lookmyshow"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.mysql_password.result
}

# Cloud SQL Proxy Service Account
resource "google_service_account" "cloudsql_proxy" {
  account_id   = "lookmyshow-cloudsql-proxy"
  display_name = "Cloud SQL Proxy Service Account"
  description  = "Service account for Cloud SQL Proxy connections"
}

resource "google_project_iam_member" "cloudsql_proxy_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_proxy.email}"
}

# Cloud Storage bucket for database backups
resource "google_storage_bucket" "db_backups" {
  name          = "${var.project_id}-lookmyshow-db-backups"
  location      = "US"
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  labels = {
    environment = var.environment
    application = "lookmyshow"
    purpose     = "database-backups"
  }
}

# Monitoring alerts for database
resource "google_monitoring_alert_policy" "database_cpu_usage" {
  display_name = "LookMyShow Database High CPU Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "Database CPU usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.primary.name}\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      duration        = "300s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "database_memory_usage" {
  display_name = "LookMyShow Database High Memory Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "Database memory usage is high"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.primary.name}\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.85
      duration        = "300s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}

# Outputs
output "primary_instance_connection_name" {
  description = "Primary database instance connection name"
  value       = google_sql_database_instance.primary.connection_name
}

output "primary_instance_private_ip" {
  description = "Primary database instance private IP"
  value       = google_sql_database_instance.primary.private_ip_address
}

output "read_replica_connection_names" {
  description = "Read replica connection names"
  value = [
    google_sql_database_instance.read_replica_east.connection_name,
    google_sql_database_instance.read_replica_europe.connection_name
  ]
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.eventsdb.name
}

output "app_username" {
  description = "Application database username"
  value       = google_sql_user.app_user.name
}

output "password_secret_name" {
  description = "Secret Manager secret name for database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "vpc_network" {
  description = "VPC network for the application"
  value       = google_compute_network.lookmyshow_vpc.name
}

output "app_subnet" {
  description = "Application subnet"
  value       = google_compute_subnetwork.app_subnet.name
} 