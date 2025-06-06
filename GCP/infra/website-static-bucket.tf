resource "google_storage_bucket" "website_static" {
  name     = var.website_bucket
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
  labels = {
    environment = var.environment
    application = "lookmyshow"
    purpose     = "website-static"
  }
}

# Note: Upload your website.zip (containing index.html, styles.css, etc.) to this bucket before running terraform apply for the VM.
# Example:
#   cd website && zip -r website.zip *
#   gsutil cp website.zip gs://<bucket-name>/website.zip 