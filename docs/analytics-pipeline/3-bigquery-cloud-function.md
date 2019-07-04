## BigQuery: Cloud Function to Native Storage

The situation might arise that querying GCS as an external table, or periodically running manual imports into native BigQuery storage, no longer suit your needs. What you want is is an active ingestion stream from GCS into native BigQuery storage.

In order to facilitate this, we provide two things:

1. A Cloud Function that picks up event files that are written into a specific GCS URI prefix.
2. A batch script to backfill events files.

### (0) - Utilizing the Cloud Function

When deploying the analytics Terraform module, you automatically also deployed the Cloud Function. Whenever events are sent to our endpoint where the URL parameter **event_category** was set to **function**, a notification is triggered that invokes our function to pick up this file & ingest it into native BigQuery storage.

The function:

- Provisions required BigQuery datasets & tables if they do not already exist.
- Verifies it is parsing ~ game events (by looking for **eventClass**).
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
  --data "{\"message\":\"hello world\"}" \
  "http://analytics.endpoints.logical-flame-194710.cloud.goog:80/v1/event?key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4&analytics_environment=testing&event_category=function&session_id=f58179a375290599dde17f7c6d546d78"
```

### (1) - Executing Backfills

The situation might arise that there are events in GCS that you wish to still ingest into native BigQuery storage using the Cloud Function. This could be because you either dropped your events table in BigQuery, or for instance did not write these events with the correct parameter setting (event_category=function).

For these situation we provide a batch script which you can point to files in GCS, and send to a Pub/Sub Topic (in our case: the Pub/Sub Topic which feeds our analytics Cloud Function). The script is written using [Apache Beam's Python SDK](https://beam.apache.org/documentation/sdks/python/), and executed on [Cloud Dataflow](https://cloud.google.com/dataflow/). As these backfills are executed on an ad-hoc basis (only when required) we do not package it up and/or deploy it into production.

First, let's create a virtual Python environment & install dependencies.

```bash
# Create a Python 3 virtual environment
python3 -m venv venv-dataflow

# Activate virtual environment
source venv-dataflow/bin/activate

# Upgrade Python's package manager pip
pip install --upgrade pip

# Install dependencies with pip
pip install -r ../../services/python/analytics-pipeline/src/requirements/dataflow.txt

# deactivate # exit virtual environment
```

Now let's boot our backfill batch script.

```bash
# Trigger script!
python ../../services/python/analytics-pipeline/src/dataflow/gcs-to-bq-backfill.py  \
  --execution-environment=DataflowRunner \
  --local-sa-key=/Users/loek/secrets/logical-flame-194710/dataflow-gcs-to-bq-stream.json \
  --gcs-bucket=gcp-analytics-pipeline-events \
  --topic=analytics-gcs-topic-dataflow \
  --gcp=logical-flame-194710
  --analytics-environment= \
  --event-category= \
  --event-ds-start= \
  --event-ds-stop= \
  --event-time =

# Note that we are simply following:
# gs://{gcs-bucket}/data_type={json|unknown}/analytics_environment={testing|development|staging|production|live}/event_category={!function}/event_ds={yyyy-mm-dd}/event_time={0-8|8-16|16-24}/*

```
