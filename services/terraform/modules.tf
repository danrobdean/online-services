# If you do not wish to deploy the gateway, comment the gateway module out!

module "gateway" {
  source           = "./module-gateway"
  gcloud_project   = "${var.gcloud_project}"
  gcloud_region    = "${var.gcloud_region}"
  gcloud_zone      = "${var.gcloud_zone}"
  k8s_cluster_name = "${var.k8s_cluster_name}"
}

# If you do not wish to deploy analytics, comment the analytics module out!

module "analytics" {
  source                           = "./module-analytics"
  gcloud_analytics_bucket_location = "EU"
  gcloud_region                    = "${var.gcloud_region}"
  gcloud_project                   = "${var.gcloud_project}"
}
