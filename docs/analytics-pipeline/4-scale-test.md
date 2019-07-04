### (4) - Scale Testing the Analytics Pipeline

<!-- Todo:
- Add temp table query. -->

Let's first write 1000 batch files to GSC:

```bash
python ../../services/python/analytics-pipeline/src/endpoint/scale-test.py \
  --gcp-secret-path=/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json \ # {LOCAL_SA_KEY_JSON}
  --host=http://analytics.endpoints.logical-flame-194710.cloud.goog/ \ # {CLOUD_PROJECT_ID}
  --api-key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4 \ # {API_KEY}
  --bucket-name=logical-flame-194710-analytics \ # {CLOUD_PROJECT_ID}-analytics
  --scale-test-name=scale-test \
  --event-category=function \
  --analytics-environment=testing \
  --pool-size=30 \
  --n=1000
```

Copy the scale test name & replace {SCALE_TEST_NAME} with it in the below query before submitting it in your terminal:

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

# Waiting on bqjob_r74008c4853c5f13c_0000016b9436e003_1 ... (1s) Current status: DONE   
# +---+------+-----------------+
# | n | freq | total_no_events |
# +---+------+-----------------+
# | 4 | 1000 |            4000 |
# +---+------+-----------------+
```
