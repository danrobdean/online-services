# Create analyics endpoint
resource "google_endpoints_service" "analytics_endpoint" {
  service_name   = "analytics${var.suffix}.endpoints.${var.gcloud_project}.cloud.goog"
  project        = "${var.gcloud_project}"
  openapi_config = "${templatefile("./module-analytics/spec/analytics-endpoint.yml", { suffix: var.suffix, project: var.gcloud_project, target: google_compute_address.analytics_ip.address })}"
}

# Enable API
resource "google_project_service" "endpoints_analytics" {
  project    = var.gcloud_project
  service    = "analytics${var.suffix}.endpoints.${var.gcloud_project}.cloud.goog"
  depends_on = [google_endpoints_service.analytics_endpoint]
}
