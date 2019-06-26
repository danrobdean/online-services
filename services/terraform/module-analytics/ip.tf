# This file defines the external IP addresses needed to expose the services

resource "google_compute_address" "analytics_ip" {
  name   = "analytics-address"
  region = var.gcloud_region
}

output "analytics_host" {
  value = google_compute_address.analytics_ip.address
}
