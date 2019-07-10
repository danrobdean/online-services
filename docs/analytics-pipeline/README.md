# The Analytics Pipeline

Before you begin..

- Make sure you have applied the [analytics Terraform module](../../services/terraform/module-analytics), to ensure all required resources for this section have been provisioned.
    + To do so, navigate into [the Terraform folder](../../services/terraform), ensure that the analytics section within [modules.tf](../../services/terraform/modules.tf) is not commented out & run `terraform init` followed by `terraform apply`.
- Afterwards, navigate to the [service account overview in the Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) and store both a JSON & P12 key from the service account named **Analytics GCS Writer** locally on your machine + write down the file paths: {**LOCAL_SA_KEY_JSON**, **LOCAL_SA_KEY_P12**}.
- The `gcloud` cli usually ships with a Python 2 interpreter, whereas we will use Python 3. Run `gcloud topic startup` for [more information](https://cloud.google.com/sdk/install) on how to point `gcloud` to a Python 3.4+ interpreter. Otherwise you could use something like [pyenv](https://github.com/pyenv/pyenv) to toggle between Python versions.

There are currently 4 parts to the analytics pipeline documentation:

1. [Creating an endpoint to POST your JSON data to, which sanitizes, augments & finally stores the events in a Google Cloud Storage (GCS) bucket](./1-cloud-endpoint.md) [**required**].
2. [Using GCS as an external data source through BigQuery](./2-bigquery-gcs-external.md) [**required**].
3. [Deploying a Cloud Function that forwards events from GCS into native BigQuery storage (as opposed to using GCS as an external data source)](./3-bigquery-cloud-function.md) [**optional**].
4. [Scale testing your analytics pipeline](./4-scale-test.md) [**optional**].
