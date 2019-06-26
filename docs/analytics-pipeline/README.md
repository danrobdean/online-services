# Python

## Analytics Pipeline

Before you begin..

1. Make sure you have applied the analytics Terraform module, to ensure all required resources have been provisioned.
2. Afterwards, navigate to the [service account overview in the Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts) and store both a JSON & P12 key locally on your machine + save the file paths.

### (0) - Running the Analytics Endpoint Locally

```bash
# Create virtual Python environment & install dependencies:
python3 -m venv venv # Create Python3 virtualenv
source venv/bin/activate # Activate venv
pip install --upgrade pip # Upgrade pip
pip install -r ../../services/python/analytics-pipeline/src/requirements-endpoint.txt # Install dependencies
# deactivate # exit virtualenv

# Set environment variables:
export GCP="logical-flame-194710"
export BUCKET_NAME="logical-flame-194710-analytics"
export SECRET_JSON="/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json" # {LOCAL_SA_KEY_JSON}
export SECRET_P12="/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.p12" # {LOCAL_SA_KEY_P12}
export EMAIL="analytics-gcs-writer@logical-flame-194710.iam.gserviceaccount.com"

# Trigger script!
python ../../services/python/analytics-pipeline/src/analytics_endpoint.py

# Verify v1/event method is working:
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"message\":\"hello world\"}" \
  "http://0.0.0.0:8080/v1/event?key=local_so_does_not_matter&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://0.0.0.0:8080/v1/file?key=local_so_does_not_matter&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"
```
_Note: The above are UNIX based commands, if you run Windows best skip this step & go straight to (1)._

### (1) - Containerizing the Analytics Endpoint

#### (1.0) - Building the Analytics Endpoint Container

```bash
# Build container:
docker build -f ../../services/docker/analytics-endpoint/Dockerfile -t "gcr.io/logical-flame-194710/analytics-endpoint" ../../services

# Check inside container:
docker run -it \
  --env GCP=logical-flame-194710 \
  --env BUCKET_NAME=logical-flame-194710-analytics \
  --env SECRET_JSON=/secrets/json/analytics-gcs-writer.json \
  --env SECRET_P12=/secrets/p12/analytics-gcs-writer.p12 \
  --env EMAIL=analytics-gcs-writer@logical-flame-194710.iam.gserviceaccount.com \
  -v /Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json:/secrets/json/analytics-gcs-writer.json \
  -v /Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.p12:/secrets/p12/analytics-gcs-writer.p12 \
  --entrypoint bash \
  gcr.io/logical-flame-194710/analytics-endpoint:latest
# Tip - Type & submit 'exit' to stop the container
```

#### (1.1) - Testing the Analytics Endpoint Container Locally

```bash
# Run container locally:
docker run \
  --env GCP=logical-flame-194710 \
  --env BUCKET_NAME=logical-flame-194710-analytics \
  --env SECRET_JSON=/secrets/json/analytics-gcs-writer.json \
  --env SECRET_P12=/secrets/p12/analytics-gcs-writer.p12 \
  --env EMAIL=analytics-gcs-writer@logical-flame-194710.iam.gserviceaccount.com \
  -v /Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json:/secrets/json/analytics-gcs-writer.json \
  -v /Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.p12:/secrets/p12/analytics-gcs-writer.p12 \
  -p 8080:8080 \
  gcr.io/logical-flame-194710/analytics-endpoint:latest

# In a different terminal window, submit curl POST requests..

# Verify v1/event method is working:
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"message\":\"hello world\"}" \
  "http://0.0.0.0:8080/v1/event?key=local_so_does_not_matter&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://0.0.0.0:8080/v1/file?key=local_so_does_not_matter&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"

# To stop the container, in a different terminal window run:
docker ps # Copy {CONTAINER_ID}
docker kill {CONTAINER_ID}
```

#### (1.2) - Pushing the Analytics Endpoint Container to Google Container Registry (GCR)

```bash
# Make sure you are in the right project
gcloud config set project {GCP_PROJECT_ID}

# Upload container to Google Container Registry (GCR)
docker push gcr.io/{GCP_PROJECT_ID}/os-analytics-endpoint:latest
docker push gcr.io/logical-flame-194710/analytics-endpoint:latest

# Verify your image is uploaded
gcloud container images list
```

#### (1.3) - Deploy Analytics Endpoint Container onto Kubernetes with Cloud Endpoints

```bash
# Make sure you have the credentials to talk to the right cluster:
gcloud container clusters get-credentials {K8S_CLUSTER_NAME} --zone {GCLOUD_ZONE}
gcloud container clusters get-credentials os-analytics-test --zone europe-west1-b

# Or if you already do - that you're configured to talk to the right cluster:
kubectl config use-context gke_logical-flame-194710_europe-west1-b_os-analytics-test

# First make all appropriate edits to files in /k8s/analytics-endpoint/ & afterwards deploy to Kubernetes:
kubectl apply -f ../../services/k8s/analytics-endpoint

# kubectl get pods
# kubectl describe pod {POD_ID} # View pod details
# kubectl logs {POD_ID} {CONTAINER_NAME} # View container logs
# kubectl exec {POD_ID} -c {CONTAINER_NAME} -it bash # Step inside running container

# Where {CONTAINER_NAME} = analytics-deployment-server or analytics-deployment-endpoint
```

#### (1.4) - Testing the Analytics Endpoint on Kubernetes

Next, [get an API key for your GCP](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes#create_an_api_key_and_set_an_environment_variable), which you need to pass via the **key** parameter in the url of your POST request: {GCP_API_KEY}. Besides this, change **logical-flame-194710** to your own {GCP_PROJECT_ID} in the destination URL of the curl request below. Note that is is currently [not possible to provision this one programmatically](https://issuetracker.google.com/issues/76227920). Also note that **it takes some time before API keys become fully functional, to be safe wait at least 10 minutes**.

```bash
# Verify v1/event method is working:
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"message\":\"hello world\"}" \
  "http://analytics.endpoints.logical-flame-194710.cloud.goog:80/v1/event?key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://analytics.endpoints.logical-flame-194710.cloud.goog:80/v1/file?key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"
```
### (2) Using the Endpoint

### (2.0) - `/v1/event`

Data that is POSTed to this endpoint will be piped into the **nwx-analytics-events** GCS bucket.

The URL takes 6 parameters:

- **key**: Required - must be tied to your GCP ([info](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes#create_an_api_key_and_set_an_environment_variable)).
- **analytics_environment**: Optional - if omitted, currently defaults to **development**.
- **event_category**: Optional - if omitted, currently defaults to **cold**.
- **event_ds**: Optional - if omitted, currently defaults to the current UTC date in **YYYY-MM-DD**.
- **event_time**: Optional - if omitted, currently defaults to current UTC time part, one of {**'0-8'**, **'8-16'**, **'16-24'**}.
- **session_id**: Optional - if omitted, currently defaults to **session-id-not-available**.

These `<parameters>` (except for **key**) influence where the data ends up in the GCS bucket:

> gs://gcp-analytics-pipeline-events/data\_type={data\_type}/analytics\_environment={analytics\_environment}/event\_category={event\_category}/event\_ds={event\_ds}/event\_time={event\_time}/{session\_id}/{ts\_fmt}\-{int}'

Note that data_type is determined automatically and can either be **json** (when valid JSON is POST'ed) or **unknown**. The fields **ts_fmt** & **int** are automatically set by the endpoint.

#### (2.0.0) - Important: the event_category Parameter

The **event_category** parameter is particularly **important**:

- When set to **function** all data contained in the POST request will be **streamed into BigQuery** using a Cloud Function.
- When set to **anything else** all data contained in the POST request will **arrive in GCS**, but will **not by default be forwarded to BigQuery**.

### (2.1) - `/v1/file`

```bash
# Assuming you have a crashdump file called worker-crashdump-test.gz..

# Get the base64 encoded md5 hash:
openssl md5 -binary worker-crashdump-test.gz | base64
# > XKvMhvwrORVuxdX54FQEdg==

# Send only this hash to endpoint, set URL parameters to define how the file ends up in GCS:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://events-api-development.endpoints.logical-flame-194710.cloud.goog:80/v1/file?key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"

# Grab the signed URL & headers from the returned JSON dictionary (if successful) & write file directly into GCS within 30 minutes:
curl \
  -H 'Content-Type: text/plain' \
  -H 'Content-MD5: XKvMhvwrORVuxdX54FQEdg==' \
  -i \
  -X PUT "https://storage.googleapis.com/gcp-analytics-pipeline-events/data_type=file/analytics_environment=testing/event_category=crashdump-worker/event_ds=2019-06-18/event_time=8-16/parent/child-451684?GoogleAccessId=event-gcs-writer%40logical-flame-194710.iam.gserviceaccount.com&Expires=1560859391&Signature=tO0bvOzgbF%2F%2FYt%2F%2BHr5L9oH1Y9yQIYMBFIuFyb36L3UhSzalq3%2FRYmto2lguceSoHEtknZQaeI1zDqRwEqfGkPTDGMY9bE1wNR9aT%2F8aAitC0czl6cOPVyJ%2FE1%2B7riEBHXcJyQQSsDMUeJWWT50OKWX4yM961kfJK7c7mv0bvwJPint7Eo5iPTyR9ax57gb4bgSgtFV5MM5c%2FvCIH7%2BuUAiXSbW9CWsA56UJRNf%2BB0YplRtB12VlxWyQlZKpHFrU5EoLQ3vO3YXsQidkjm1it%2BCl1uQptvX%2BZCI7eleEiZANpVX46%2B0MFSXi%2FidMHQSVEF96iGTaFvwzpoiT%2Bj%2F42g%3D%3D" \
  --data-binary '@worker-crashdump-test.gz'
```

### (3) Manually Importing Data Events from GCS into BigQuery

#### (3.0) - Option 1: Querying GCS directly using a temporary table is possible through the Command Line

```bash
bq --location=EU query \
   --use_legacy_sql=false \
   --external_table_definition=temporary_table::buildVersion:STRING,eventType:STRING@NEWLINE_DELIMITED_JSON=gs://gcp-analytics-pipeline-events/data_type=json/analytics_environment=testing/event_category=cold/\* \
   'SELECT buildVersion, eventType, COUNT(*) AS n FROM temporary_table GROUP BY 1, 2;'

 # Waiting on bqjob_r686b1eba38dfa29f_0000016a7404cf2a_1 ... (0s) Current status: DONE   
 # +--------------+----------------------------+------+
 # | buildVersion |         eventType          |  n   |
 # +--------------+----------------------------+------+
 # | 2.0.13       | scale-test-1000-1556724049 | 4000 |
 # +--------------+----------------------------+------+
```

#### (3.1) - Option 2: Importing the files in GCS into a Native or External table (which then allows subsequent querying)

- Go to your BigQuery overview, click on a dataset & then **Create Table**. Fill out form & hit **Create table** again, example input:
    + Table name: **events_gcs**
    + Table type: choose **External** to establish a live link between GCS & BigQuery or **Native**, which imports the data "as of now" into a static table in BigQuery. Note that querying an External table will dynamically (re-)parse all files present in your GCS URI (below).
    + GCS URI: **gs://gcp-analytics-pipeline-events/data_type=json/analytics_environment=testing/event_category=cold/***
    + Schema: **eventIndex:INTEGER,buildVersion:STRING,eventType:STRING,sessionId:STRING,eventEnvironment:STRING,eventSource:STRING,eventTimestamp:TIMESTAMP,eventAttributes:STRING,eventClass:STRING,receivedTimestamp:TIMESTAMP**
- Usage notes:
    + Values denoted in the **schema** that are **not present in the event** JSON dictionary in GCS will be shown as **NULL in BigQuery**.
    + If you want to omit importing certain event attributes by excluding them from the schema, you **must** select **"Ignore unknown values"**.

_Tip: The GCS file path [accepts wildcards](https://cloud.google.com/bigquery/external-data-cloud-storage#wildcard-support)._

### (4) - Writing Events to the Cloud Function

```bash
python ../../services/python/analytics-pipeline/src/analytics_endpoint_scale_test.py \
  --gcp-secret-path=/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json \
  --host=http://analytics.endpoints.logical-flame-194710.cloud.goog/ \
  --api-key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4 \
  --bucket-name=logical-flame-194710-analytics \
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

### (5) - Cleanup

```bash
# Obtain list of all your deployments
kubectl get deployments

# Delete your deployment:
kubectl delete deployment {K8S_DEPLOYMENT_NAME}
kubectl delete deployment analytics-deployment

# Obtain list of all your services
kubectl get services

# Delete your service
kubectl delete service {K8S_SERVICE_NAME}
kubectl delete service analytics-service
```
