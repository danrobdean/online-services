# Scale Testing the Analytics Pipeline

In this section we will scale test our analytics pipeline.

1. [Write Events](1---write-events)
2. [Verify Events](2---verify-events)

## (1) - Write Events

First let's create a virtual Python environment & install dependencies.

```bash
# Create a Python 3 virtual environment
python3 -m venv venv-scale-test

# Activate virtual environment
source venv-scale-test/bin/activate

# Upgrade Python's package manager pip
pip install --upgrade pip

# Install dependencies with pip
pip install -r ../../services/python/analytics-pipeline/src/requirements/scale-test.txt

# Exit virtual environment:
# deactivate
```

Second, we will write 10k batch files into GSC:

```bash
python ../../services/python/analytics-pipeline/src/endpoint/scale-test.py \
  --gcp-secret-path={LOCAL_SA_KEY_JSON} \
  --host=http://analytics.endpoints.{GCLOUD_PROJECT_ID}.cloud.goog/ \
  --api-key={GCP_API_KEY} \
  --bucket-name={GCLOUD_PROJECT_ID}-analytics \
  --scale-test-name=scale-test \
  --event-category=function \
  --analytics-environment=testing \
  --pool-size=30 \
  --n=10000
```

After the script finishes, copy the {SCALE_TEST_NAME}, {EVENT_DS} & {EVENT_TIME} from the output.

## (2) - Verify Events

### (2.1) - In GCS

Verify whether our events arrived successfully in GCS:

```bash
QUERY="
SELECT
  a.n,
  COUNT(*) AS freq,
  a.n * COUNT(*) AS total_no_events
FROM
    (
    SELECT
      batchId,
      COUNT(*) AS n
    FROM table_test
    WHERE eventType = '{SCALE_TEST_NAME}'
    GROUP BY 1
    ) a
GROUP BY 1
;
"
bq \
  --location=EU \
  --use_legacy_sql=false \
  --external_table_definition=table_test::batchId:STRING,eventType:STRING@NEWLINE_DELIMITED_JSON=gs://{CLOUD_PROJECT_ID}-analytics/data_type=json/analytics_environment=testing/event_category=function/event_ds={EVENT_DS}/event_time={EVENT_TIME}/{SCALE_TEST_NAME}/\* \
  $QUERY

# +---+-------+------------------+
# | n | freq  | total_no_events  |
# +---+-------+------------------+
# | 4 | 10000 |            40000 |
# +---+-------+------------------+
```

### (2.2) - In BigQuery

Next we verify whether our analytics Cloud Function successfully forwarded these events into native BigQuery storage:

```bash
QUERY="
SELECT
  a.n,
  COUNT(*) AS freq,
  a.n * COUNT(*) AS total_no_events
FROM
    (
    SELECT batch_id, COUNT(*) as n
    FROM events.events_function
    WHERE event_type = '{SCALE_TEST_NAME}'
    GROUP BY 1
    ) a
GROUP BY 1
;
"
bq query --use_legacy_sql=false $QUERY

# +---+-------+------------------+
# | n | freq  | total_no_events  |
# +---+-------+------------------+
# | 4 | 10000 |            40000 |
# +---+-------+------------------+
```
