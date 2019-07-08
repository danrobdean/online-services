# BigQuery: Cloud Function to Native Storage

The situation might arise that querying GCS as an external table, or periodically running manual imports into native BigQuery storage, no longer suit your needs. What you might want is an active ingestion stream from GCS into native BigQuery storage.

In order to facilitate this, we provide two things:

1. [A Cloud Function that picks up event files that are written into a specific GCS URI prefix, and forwards them into native BigQuery storage.](#1---utilizing-the-cloud-function)
2. [A batch script to backfill events files.](#2---executing-backfills)

## (1) - Utilizing the Cloud Function

When deploying [the analytics Terraform module](https://github.com/improbable/online-services/tree/master/services/terraform), you automatically also deployed the analytics Cloud Function. Whenever events are sent to our endpoint where the URL parameter **event_category** was set to **function**, a notification is triggered that invokes our function to pick up this file & ingest it into native BigQuery storage. Only when a Cloud Function is invoked, do you accrue any costs.

The function:

- Provisions required BigQuery datasets & tables if they do not already exist.
- Verifies it is parsing ~ game events (by looking for **eventClass** in each event).
- Safely parses all expected event keys:
    + It tries parsing keys as both camelCase & snake_case.
    + It returns NULL if key not present.
    + It ignores unexpected keys.
- Augments the events with a **job_name** & an **inserted_timestamp**.
- Writes the events into an events table, a log into a logs table & in case parsing failed an error into a debug table.

In order to utilize the function, you have to make sure **event_category** is set to **function** when POST'ing your events:

```bash
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"eventSource\":\"client\",\"eventClass\":\"test\",\"eventType\":\"cloud_function\",\"eventTimestamp\":1562599755,\"eventIndex\":6,\"sessionId\":\"f58179a375290599dde17f7c6d546d78\",\"buildVersion\":\"2.0.13\",\"eventEnvironment\":\"testing\",\"eventAttributes\":{\"playerId\": 12345678}}" \
  "http://analytics.endpoints.{GCLOUD_PROJECT_ID}.cloud.goog:80/v1/event?key={GCP_API_KEY}&analytics_environment=testing&event_category=function&session_id=f58179a375290599dde17f7c6d546d78"

```

## (2) - Executing Backfills

The situation might arise that there are events in GCS that you wish to still ingest into native BigQuery storage using the Cloud Function. This could be because you either dropped your events table in BigQuery, or for instance did not write these events with the correct parameter setting (`..&event_category=function..`).

For these situation we provide a batch script which you can point to:

1. Files in GCS.
2. A Pub/Sub Topic that should receive notifications about the existence of these files (in our case: the Pub/Sub Topic which feeds our analytics Cloud Function).

The script is written using [Apache Beam's Python SDK](https://beam.apache.org/documentation/sdks/python/), and executed on [Cloud Dataflow](https://cloud.google.com/dataflow/). As these backfills are executed on an ad-hoc basis (only when required) we do not package it up and/or deploy it into production.

First, navigate to the [service account overview in the Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) and store a JSON key from the service account named **Dataflow Batch** locally on your machine + write down the file path: {**LOCAL_SA_KEY_JSON_DATAFLOW**}

Second, let's create a virtual Python environment & install dependencies:

```bash
# Create a Python 3 virtual environment:
python3 -m venv venv-dataflow

# Activate virtual environment:
source venv-dataflow/bin/activate

# Upgrade Python's package manager pip:
pip install --upgrade pip

# Install dependencies with pip:
pip install -r ../../services/python/analytics-pipeline/src/requirements/dataflow.txt

# Exit virtual environment:
# deactivate
```

Now let's boot our backfill batch script:

```bash
# Trigger script!
python ../../services/python/analytics-pipeline/src/dataflow/gcs-to-bq-backfill.py  \
  --execution-environment=DataflowRunner \
  --local-sa-key={LOCAL_SA_KEY_JSON_DATAFLOW} \
  --gcs-bucket={GCLOUD_PROJECT_ID}-analytics \
  --topic=cloud-function-gcs-to-bq-topic \
  --gcp=GCLOUD_PROJECT_ID}
  --analytics-environment=testing \
  --event-category=cold \
  --event-ds-start=2019-01-01 \
  --event-ds-stop=2019-01-31 \
  --event-time=0-8
```

Note that we are simply following:

> gs://{gcs-bucket}/data_type=json/analytics_environment={testing|development|staging|production|live}/event_category={!function}/event_ds={yyyy-mm-dd}/event_time={0-8|8-16|16-24}/*

Check out the execution of your Dataflow Batch script in [the Dataflow Console](https://console.cloud.google.com/dataflow)!
