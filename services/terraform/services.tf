# This file is used to explicitly enable required Google Cloud services and define API endpoints.

resource "google_project_service" "servicemanagement" {
  project = "${var.gcloud_project}"
  service = "servicemanagement.googleapis.com"
}

resource "google_project_service" "servicecontrol" {
  project = "${var.gcloud_project}"
  service = "servicecontrol.googleapis.com"
}

resource "google_project_service" "endpoints" {
  project = "${var.gcloud_project}"
  service = "endpoints.googleapis.com"
}

resource "google_project_service" "redis" {
  project = var.gcloud_project
  service = "redis.googleapis.com"
}

resource "google_project_service" "container" {
  project = "${var.gcloud_project}"
  service = "container.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  project = "${var.gcloud_project}"
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "iam" {
  project = "${var.gcloud_project}"
  service = "iam.googleapis.com"
}
