
resource "google_storage_bucket_object" "function_analytics" {
  name   = "analytics/function-gcs-to-bq.zip"
  bucket = "${google_storage_bucket.functions_bucket.name}"
  source = "${path.module}/../../python/analytics-pipeline/cloud-function-analytics.zip"
}

resource "google_cloudfunctions_function" "function" {
  name                  = "function-gcs-to-bq"
  description           = "GCS to BigQuery Cloud Function"
  runtime               = "python37"

  available_memory_mb   = 256
  source_archive_bucket = "${google_storage_bucket.functions_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.function_analytics.name}"
  timeout               = 60
  entry_point           = "cf0GcsToBq"
  service_account_email = "${google_service_account.cloud_function_gcs_to_bq.email}"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "${google_pubsub_topic.cloud_function_gcs_to_bq_topic.name}"
  }

}
