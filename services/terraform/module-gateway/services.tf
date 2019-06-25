resource "google_endpoints_service" "gateway_endpoint" {
  service_name         = "gateway.endpoints.${var.gcloud_project}.cloud.goog"
  project              = "${var.gcloud_project}"
  grpc_config          = "${templatefile("./module-gateway/spec/gateway_spec.yml", { project: var.gcloud_project, target: google_compute_address.gateway_ip.address })}"
  protoc_output_base64 = "${filebase64("./module-gateway/api_descriptors/gateway_descriptor.pb")}"
}

resource "google_endpoints_service" "party_endpoint" {
  service_name         = "party.endpoints.${var.gcloud_project}.cloud.goog"
  project              = "${var.gcloud_project}"
  grpc_config          = "${templatefile("./module-gateway/spec/party_spec.yml", { project: var.gcloud_project, target: google_compute_address.party_ip.address })}"
  protoc_output_base64 = "${filebase64("./module-gateway/api_descriptors/party_descriptor.pb")}"
}

resource "google_endpoints_service" "playfab_auth_endpoint" {
  service_name         = "playfab-auth.endpoints.${var.gcloud_project}.cloud.goog"
  project              = "${var.gcloud_project}"
  grpc_config          = "${templatefile("./module-gateway/spec/playfab_auth_spec.yml", { project: var.gcloud_project, target: google_compute_address.playfab_auth_ip.address })}"
  protoc_output_base64 = "${filebase64("./module-gateway/api_descriptors/playfab_auth_descriptor.pb")}"
}
