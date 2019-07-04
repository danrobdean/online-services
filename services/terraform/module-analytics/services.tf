# This file enables a required API & creates our Cloud Endpoint service.

# Enable API.
resource "google_project_service" "endpoints_analytics" {
  project    = var.gcloud_project
  service    = "analytics.endpoints.${var.gcloud_project}.cloud.goog"
  depends_on = [google_endpoints_service.analytics_endpoint]
}

# Create analytics endpoint.
resource "google_endpoints_service" "analytics_endpoint" {
  service_name   = "analytics.endpoints.${var.gcloud_project}.cloud.goog"
  project        = "${var.gcloud_project}"
  openapi_config = "${templatefile("./module-analytics/spec/analytics-endpoint.yml", { project: var.gcloud_project, target: google_compute_address.analytics_ip.address })}"
}

# Declare output variable.
output "analytics_dns" {
  value = "${google_endpoints_service.analytics_endpoint.dns_address}"
}
