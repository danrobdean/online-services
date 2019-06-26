
resource "google_storage_bucket" "analytics_bucket" {
  # force_destroy = True
  name          = "${var.gcloud_project}-${var.gcloud_analytics_bucket_name}"
  location      = var.gcloud_analytics_bucket_location
  storage_class = "MULTI_REGIONAL"
}
