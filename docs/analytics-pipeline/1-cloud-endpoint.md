# Cloud Endpoint

This part covers the creation of an endpoint to forward analytics data to, which acts as the start of the analytics pipeline.

- The first section will outline how to test, verify & deploy the endpoint onto Kubernetes.
- The second section will cover how to actually use the 2 endpoint methods: **event** & **file**.
- The third section will show how to do some optional cleanup on Kubernetes.

## (1) - Testing, Verifying & Deploying the Analytics Endpoint

### (1.1) - Triggering the Server Code Directly

We will start by calling the script directly via the command line, which will start a local running execution of our endpoint.

_Note: The below are UNIX based commands, if you run Windows best skip this step & go straight to (1)._

```bash
# Create a Python 3 virtual environment:
python3 -m venv venv-endpoint

# Activate virtual environment:
source venv-endpoint/bin/activate

# Upgrade Python's package manager pip:
pip install --upgrade pip

# Install dependencies with pip:
pip install -r ../../services/python/analytics-pipeline/src/requirements/endpoint.txt

# Set required environment variables
export GCP="logical-flame-194710" # {GCP_ID}
export BUCKET_NAME="logical-flame-194710-analytics" # {GCP_ID}-analytics
export SECRET_JSON="/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.json" # {LOCAL_SA_KEY_JSON}
export SECRET_P12="/Users/loek/secrets/logical-flame-194710/analytics-gcs-writer.p12" # {LOCAL_SA_KEY_P12}
export EMAIL="analytics-gcs-writer@logical-flame-194710.iam.gserviceaccount.com" # analytics-gcs-writer@{GCP_ID}.iam.gserviceaccount.com

# Trigger script!
python ../../services/python/analytics-pipeline/src/endpoint/main.py
# Press Cntrl + C in order to halt execution of the endpoint.

# Exit virtual environment:
# deactivate
```

In a different terminal window, submit the following 2 `curl` POST requests in order to verify the endpoint is working as expected:

```bash
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

If both requests returned proper JSON, without any error messaging, the endpoint is working as anticipated! :tada:

### (1.2) - Containerizing the Analytics Endpoint

Next we are going containerize our analytics endpoint. We will then verify it is still working by executing the container locally. Once we have verified this is the case, we will push the container to a remote location, in this case Google Container Registry (GCR). This stages the container to be deployed on top of Google's fully managed Kubernetes solution: Google Kubernetes Engine (GKE).

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

Now let's verify the container is working as expected, by running it locally:

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
```

As before, in a different terminal window, submit the follow 2 curl POST requests:

```bash
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

In case the requests were successful, we can now push the container to GCR.

```bash
# Make sure you are in the right project
gcloud config set project {GCP_PROJECT_ID}

# Upload container to Google Container Registry (GCR)
docker push gcr.io/{GCP_PROJECT_ID}/os-analytics-endpoint:latest
docker push gcr.io/logical-flame-194710/analytics-endpoint:latest

# Verify your image is uploaded
gcloud container images list
```

### (1.3) - Deploying Analytics Endpoint Container onto GKE with Cloud Endpoints

At this point we have a working container hosted in GCR, which GKE can pull containers from. We will now deploy our analytics endpoint on top of GKE.

```bash
# Make sure you have the credentials to talk to the right cluster:
gcloud container clusters get-credentials {K8S_CLUSTER_NAME} --zone {GCLOUD_ZONE}
gcloud container clusters get-credentials os-analytics-test --zone europe-west1-b

# Or if you already do - that you're configured to talk to the right cluster:
kubectl config use-context {K8S_CONTEXT_NAME}
```

Now **make all appropriate edits to the files in [../../services/k8s/analytics-endpoint/](https://github.com/improbable/online-services/tree/analytics/services/k8s/analytics-endpoint)** & afterwards deploy them to Kubernetes:

```bash
kubectl apply -f ../../services/k8s/analytics-endpoint
```

The following commands can help you check what is happening & potentially debug any issues. Note a pod is generally a group of containers running together. In our case, each pod contains two containers: one running our custom server code & one public Google container that runs everything related to Cloud Endpoints. We are running 3 replicas of our pod together in a single deployment. This means we have 2 x 3 = 6 containers running in our deployment.

```bash
# Show me all deployments:
kubectl get deployments

# Show me all pods:
kubectl get pods

# View details of pods:
kubectl describe pod {POD_ID}

# Show logs of a specific container:
kubectl logs {POD_ID} {CONTAINER_NAME}

# Step inside running container
kubectl exec {POD_ID} -c {CONTAINER_NAME} -it bash

# Where {CONTAINER_NAME} = analytics-deployment-server or analytics-deployment-endpoint
```

Next, [get an API key for your GCP](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes#create_an_api_key_and_set_an_environment_variable), which you need to pass via the **key** parameter in the url of your POST request: {GCP_API_KEY}. Besides this, change **logical-flame-194710** to your own {GCP_PROJECT_ID} in the destination URL of the curl request below. Note that is is currently [not possible to provision this one programmatically](https://issuetracker.google.com/issues/76227920). Also note that **it takes some time before API keys become fully functional, to be safe wait at least 10 minutes** before attempting the below POST requests.

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

If both requests succeeded, this means you have now deployed your Analytics Endpoint! :confetti_ball:

## (2) Using the Endpoint

### (2.0) - `/v1/event`

This method enables you to store analytics events in your GCS analytics bucket. The method accepts JSON dicts (one for each event), either standalone or batched up in lists (recommended). Each POST request will create a file in GCS, with the event dictionaries newline delimited (in case a JSON list was POST'ed).

The URL takes 6 parameters:

| Parameter             | Class    | Description |
|-----------------------|------------------------|
| key                   | Required | Must be tied to your GCP ([info](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes#create_an_api_key_and_set_an_environment_variable)). |
| analytics_environment | Optional | If omitted, currently defaults to **development**, otherwise must be one of {**'testing'**, '**development**', '**staging**', '**production**', '**live**'}. |
| event_category        | Optional | If omitted, currently defaults to **cold**. |
| event_ds              | Optional | If omitted, currently defaults to the current UTC date in **YYYY-MM-DD**. |
| event_time            | Optional | If omitted, currently defaults to current UTC time part, otherwise must be one of {**'0-8'**, **'8-16'**, **'16-24'**}. |
| session_id            | Optional | If omitted, currently defaults to **session-id-not-available**. |

These `<parameters>` (except for **key**) influence where the data ends up in the GCS bucket:

> gs://gcp-analytics-pipeline-events/data\_type={data\_type}/analytics\_environment={analytics\_environment}/event\_category={event\_category}/event\_ds={event\_ds}/event\_time={event\_time}/{session\_id}/{ts\_fmt}\-{int}'

Note that data_type is determined automatically and can either be **json** (when valid JSON is POST'ed) or **unknown** (otherwise). The fields **ts_fmt** & **int** are automatically set by the endpoint as well.

#### (2.0.0) - Important: the event_category Parameter

The **event_category** parameter is particularly **important**:

- When set to **function** all data contained in the POST request will be **ingested into native BigQuery storage** using the Cloud Function we created when we deployed [the analytics module with Terraform]((https://github.com/improbable/online-services/tree/master/services/terraform)).
- When set to **anything else** all data contained in the POST request will **arrive in GCS**, but will **not by default be ingested into native BigQuery storage**. This data can however still be accessed by BigQuery by using GCS as an external data source.

#### (2.0.1) - The JSON Event Schema

| Key              | Type    | Description |
|------------------|------------------------
| eventEnvironment | string  | One of  {**testing**, **development**, **staging**, **production**}. |
| eventIndex       | integer | Increments with one with each event per eventSource, allows us to spot missing data. |
| eventSource      | string  | Source of the event, e.g. worker type. |
| eventClass       | string  | A higher order mnemonic classification of events (e.g. session). |
| eventType        | string  | A mnemonic event identifier (e.g. session_start). |
| sessionId        | string  | The session_id, which is unique per client/server session. |
| buildVersion     | string  | Version of the build, should naturally sort from oldest to latest. |
| eventTimestamp   | float   | The timestamp of the event, in unix time. |
| eventAttributes  | dict    | Anything else relating to this particular event will be captured in this attribute as a nested JSON dictionary. |

### (2.1) - `/v1/file`

This method allows you to write large files straight into GCS, without having to route the entire file contents via the Analytics Endpoint (which might otherwise overload it). The process entails requesting a signed URL which authorizes your server/client to write a specific file (based on its base64 encoded md5 hash) to a specific location in GCS within 30 minutes.

Assuming you have a crashdump file called **worker-crashdump-test.gz**:

```bash
# Get the base64 encoded md5 hash:
openssl md5 -binary worker-crashdump-test.gz | base64
# > XKvMhvwrORVuxdX54FQEdg==

# Send only this hash to endpoint, set URL parameters to define how the file ends up in GCS:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://analytics.endpoints.logical-flame-194710.cloud.goog:80/v1/file?key=AIzaSyCP3Feg6_dLZ7sze9gsjhXRg7XFfPxKrl4&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"

# Grab the signed URL & headers from the returned JSON dictionary (if successful) & write file directly into GCS within 30 minutes:
curl \
  -H 'Content-Type: text/plain' \
  -H 'Content-MD5: XKvMhvwrORVuxdX54FQEdg==' \
  -X PUT "https://storage.googleapis.com/gcp-analytics-pipeline-events/data_type=file/analytics_environment=testing/event_category=crashdump-worker/event_ds=2019-06-18/event_time=8-16/parent/child-451684?GoogleAccessId=event-gcs-writer%40logical-flame-194710.iam.gserviceaccount.com&Expires=1560859391&Signature=tO0bvOzgbF%2F%2FYt%2F%2BHr5L9oH1Y9yQIYMBFIuFyb36L3UhSzalq3%2FRYmto2lguceSoHEtknZQaeI1zDqRwEqfGkPTDGMY9bE1wNR9aT%2F8aAitC0czl6cOPVyJ%2FE1%2B7riEBHXcJyQQSsDMUeJWWT50OKWX4yM961kfJK7c7mv0bvwJPint7Eo5iPTyR9ax57gb4bgSgtFV5MM5c%2FvCIH7%2BuUAiXSbW9CWsA56UJRNf%2BB0YplRtB12VlxWyQlZKpHFrU5EoLQ3vO3YXsQidkjm1it%2BCl1uQptvX%2BZCI7eleEiZANpVX46%2B0MFSXi%2FidMHQSVEF96iGTaFvwzpoiT%2Bj%2F42g%3D%3D" \
  --data-binary '@worker-crashdump-test.gz'
```

## (3) - GKE Cleanup

In case you want remove your workloads from GKE, you can run the following commands:

```bash
# Obtain list of all your deployments:
# kubectl get deployments

# Delete your deployment:
# kubectl delete deployment {K8S_DEPLOYMENT_NAME}

# Obtain list of all your services:
# kubectl get services

# Delete your service:
# kubectl delete service {K8S_SERVICE_NAME}
```
