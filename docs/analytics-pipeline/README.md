# The Analytics Pipeline

Before you begin..

- Make sure you have applied the [analytics Terraform module](https://github.com/improbable/online-services/tree/master/services/terraform), to ensure all required resources for this section have been provisioned.
- Afterwards, navigate to the [service account overview in the Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) and store both a JSON & P12 key from the service account named **Analytics GCS Writer** locally on your machine + write down the file paths: {**LOCAL_SA_KEY_JSON**, **LOCAL_SA_KEY_P12**}.

There are currently 4 parts to the analytics pipeline documentation:

1. Creating an endpoint to POST your JSON data to, which sanitizes, augments & finally stores the events in a Google Cloud Storage (GCS) bucket [**required**].
2. Using GCS as an external data source through BigQuery [**required**].
3. Deploying a Cloud Function that forwards events from GCS into native BigQuery storage (as opposed to using GCS as an external data source) [**optional**].
4. Scale testing your analytics pipeline [**optional**].
