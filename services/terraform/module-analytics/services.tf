# Generate random pet name
resource "random_pet" "pet" {
  length = 1
  keepers = {
    # Change pet_name if we change IP address..
    ip = "${google_compute_address.analytics_ip.address}"
  }
}

# Create analyics endpoint
resource "google_endpoints_service" "analytics_endpoint" {
  service_name   = "analytics-${random_pet.pet.id}.endpoints.${var.gcloud_project}.cloud.goog"
  project        = "${var.gcloud_project}"
  openapi_config = "${templatefile("./module-analytics/spec/analytics-endpoint.yml", { suffix: random_pet.pet.id, project: var.gcloud_project, target: google_compute_address.analytics_ip.address })}"
}

# Enable API
resource "google_project_service" "endpoints_analytics" {
  project    = var.gcloud_project
  service    = "analytics-${random_pet.pet.id}.endpoints.${var.gcloud_project}.cloud.goog"
  depends_on = [google_endpoints_service.analytics_endpoint]
}

output "analytics_dns" {
  value = google_endpoints_service.analytics_endpoint.dns_address
}
