# This files creates two GCS buckets.

resource "google_storage_bucket" "analytics_bucket" {
  # force_destroy = True
  name          = "${var.gcloud_project}-analytics"
  location      = var.gcloud_analytics_bucket_location
  storage_class = "MULTI_REGIONAL"
}

resource "google_storage_bucket" "functions_bucket" {
  # force_destroy = True
  name          = "${var.gcloud_project}-cloud-functions"
  location      = var.gcloud_analytics_bucket_location
  storage_class = "MULTI_REGIONAL"
}
