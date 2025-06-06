# LookMyShow App Engine Deployment (Application Tier)

resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = var.region
}

resource "google_app_engine_standard_app_version" "default" {
  service         = "default"
  version_id      = "v1"
  runtime         = "python39"
  entrypoint {
    shell = "gunicorn -b :$PORT main:app"
  }
  deployment {
    zip {
      source_url = "gs://${var.project_id}-lookmyshow-app-bucket/app.zip"
    }
  }
  env_variables = {
    DB_HOST     = "127.0.0.1"
    DB_USER     = "lookmyshow_app"
    DB_PASSWORD = "{{resolve:secretmanager:lookmyshow-db-password:latest}}"
    DB_NAME     = "eventsdb"
  }
  automatic_scaling {}
  noop_on_destroy = true
  depends_on = [google_app_engine_application.app]
} 