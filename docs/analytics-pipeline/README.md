# Python

## Analytics Pipeline

Before you begin..

- Make sure you have applied the analytics [Terraform](https://github.com/improbable/online-services/tree/analytics/services/terraform) module, to ensure all required resources have been provisioned.
- Afterwards, navigate to the [service account overview in the Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) and store both a JSON & P12 key from the service account named **Analytics GCS Writer** locally on your machine + save the file paths {LOCAL_SA_KEY_JSON, LOCAL_SA_KEY_P12}.

There are currently three parts to the analytics pipeline:

1. An endpoint to POST your JSON data to, and stores the events in a Google Cloud Storage (GCS) bucket (**required**).
2. Using Google Cloud Storage as an external data source within BigQuery (**required**).
3. A Cloud Function that takes events from GCS & ingests them into native BigQuery storage (optional).
4. Scale testing your analytics pipeline (optional).
