# Create Pub/Sub Topic
resource "google_pubsub_topic" "cloud_function_gcs_to_bq_topic" {
  name = "cloud-function-gcs-to-bq-topic"
}

# Enable notifications by giving the correct IAM permission to the unique service account.
data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "member_cloud_function" {
    topic   = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.name}"
    role    = "roles/pubsub.publisher"
    member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Create GCS to Pub/Sub Topic Notifications

resource "google_storage_notification" "notification_function_development" {
    # This GCS bucket below should have already been provisioned here:
    # https://github.com/improbable/production-analytics-demo/blob/master/1-Analytics-Pipeline/1-Deploy-Event-Service/terraform/main.tf
    bucket             = "${var.gcloud_project}-analytics"
    payload_format     = "JSON_API_V1"
    topic              = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.id}"
    # See other event_types here: https://cloud.google.com/storage/docs/pubsub-notifications#events
    event_types        = ["OBJECT_FINALIZE"]
    # Only trigger a message to Pub/Sub for files hitting the development/event/ folder
    object_name_prefix = "data_type=json/analytics_environment=development/event_category=function/"
    depends_on         = ["google_pubsub_topic_iam_member.member_cloud_function"]
}

resource "google_storage_notification" "notification_function_testing" {
    # This GCS bucket below should have already been provisioned here:
    # https://github.com/improbable/production-analytics-demo/blob/master/1-Analytics-Pipeline/1-Deploy-Event-Service/terraform/main.tf
    bucket             = "${var.gcloud_project}-analytics"
    payload_format     = "JSON_API_V1"
    topic              = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.id}"
    # See other event_types here: https://cloud.google.com/storage/docs/pubsub-notifications#events
    event_types        = ["OBJECT_FINALIZE"]
    # Only trigger a message to Pub/Sub for files hitting the development/event/ folder
    object_name_prefix = "data_type=json/analytics_environment=testing/event_category=function/"
    depends_on         = ["google_pubsub_topic_iam_member.member_cloud_function"]
}

resource "google_storage_notification" "notification_function_staging" {
    # This GCS bucket below should have already been provisioned here:
    # https://github.com/improbable/production-analytics-demo/blob/master/1-Analytics-Pipeline/1-Deploy-Event-Service/terraform/main.tf
    bucket             = "${var.gcloud_project}-analytics"
    payload_format     = "JSON_API_V1"
    topic              = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.id}"
    # See other event_types here: https://cloud.google.com/storage/docs/pubsub-notifications#events
    event_types        = ["OBJECT_FINALIZE"]
    # Only trigger a message to Pub/Sub for files hitting the development/event/ folder
    object_name_prefix = "data_type=json/analytics_environment=staging/event_category=function/"
    depends_on         = ["google_pubsub_topic_iam_member.member_cloud_function"]
}

resource "google_storage_notification" "notification_function_production" {
    # This GCS bucket below should have already been provisioned here:
    # https://github.com/improbable/production-analytics-demo/blob/master/1-Analytics-Pipeline/1-Deploy-Event-Service/terraform/main.tf
    bucket             = "${var.gcloud_project}-analytics"
    payload_format     = "JSON_API_V1"
    topic              = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.id}"
    # See other event_types here: https://cloud.google.com/storage/docs/pubsub-notifications#events
    event_types        = ["OBJECT_FINALIZE"]
    # Only trigger a message to Pub/Sub for files hitting the development/event/ folder
    object_name_prefix = "data_type=json/analytics_environment=production/event_category=function/"
    depends_on         = ["google_pubsub_topic_iam_member.member_cloud_function"]
}

# Create Pub/Sub Subscription
# resource "google_pubsub_subscription" "cloud_function_gcs_to_bq_subscription" {
#   name                 = "cloud-function-gcs-to-bq-subscription"
#   topic                = "${google_pubsub_topic.analytics_topic_cloud_function.name}"
#   ack_deadline_seconds = 600
# }
