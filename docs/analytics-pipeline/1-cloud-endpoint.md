# Cloud Endpoint

This part covers the creation of an endpoint to forward analytics data to, which acts as the start of the analytics pipeline.

1. [Initiating, Verifying & Deploying the Analytics Endpoint](#1---initiating-verifying--deploying-the-analytics-endpoint)
2. [How to Use the Endpoint](#2---how-to-use-the-endpoint)
3. [GKE Cleanup & Debug](#3---gke-debug--cleanup)

## (1) - Initiating, Verifying & Deploying the Analytics Endpoint

### (1.1) - Triggering the Server Code Directly

We will start by calling the script directly via the command line, which will start a local running execution of our endpoint.

_Note: The below are UNIX based commands, if you run Windows best skip this step & go straight to [(1.2)](#12---containerizing-the-analytics-endpoint)._

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
export GCP={GCLOUD_PROJECT_ID}
export BUCKET_NAME={GCLOUD_PROJECT_ID}-analytics
export SECRET_JSON={LOCAL_SA_KEY_JSON}
export SECRET_P12={LOCAL_SA_KEY_P12}
export EMAIL=analytics-gcs-writer@{GCLOUD_PROJECT_ID}.iam.gserviceaccount.com

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
  --data "{\"eventSource\":\"client\",\"eventClass\":\"test\",\"eventType\":\"endpoint_local\",\"eventTimestamp\":1562599755,\"eventIndex\":6,\"sessionId\":\"f58179a375290599dde17f7c6d546d78\",\"buildVersion\":\"2.0.13\",\"eventEnvironment\":\"testing\",\"eventAttributes\":{\"playerId\": 12345678}}" \
  "http://0.0.0.0:8080/v1/event?key=local_so_does_not_matter&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://0.0.0.0:8080/v1/file?key=local_so_does_not_matter&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"  
```

If both requests returned proper JSON, without any error messages, the endpoint is working as expected! :tada:

### (1.2) - Containerizing the Analytics Endpoint

Next we are going containerize our analytics endpoint using [Docker](https://www.docker.com/). We will then verify it is still working by executing the container locally. Once we have verified this is the case, we will push the container to a remote location, in this case [Google Container Registry (GCR)](https://cloud.google.com/container-registry/). This stages the container to be deployed on top of Google's fully managed Kubernetes solution: [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/).

```bash
# Build container:
docker build -f ../../services/docker/analytics-endpoint/Dockerfile -t "gcr.io/{GCLOUD_PROJECT_ID}/analytics-endpoint" ../../services

# Check inside container:
docker run -it \
  --env GCP={GCLOUD_PROJECT_ID} \
  --env BUCKET_NAME={GCLOUD_PROJECT_ID}-analytics \
  --env SECRET_JSON=/secrets/json/analytics-gcs-writer.json \
  --env SECRET_P12=/secrets/p12/analytics-gcs-writer.p12 \
  --env EMAIL=analytics-gcs-writer@{GCLOUD_PROJECT_ID}.iam.gserviceaccount.com \
  -v {LOCAL_SA_KEY_JSON}:/secrets/json/analytics-gcs-writer.json \
  -v {LOCAL_SA_KEY_P12}:/secrets/p12/analytics-gcs-writer.p12 \
  --entrypoint bash \
  gcr.io/{GCLOUD_PROJECT_ID}/analytics-endpoint:latest

# Tip - Type & submit 'exit' to stop the container
```

Now let's verify the container is working as expected, by running it locally:

```bash
# Run container locally:
docker run \
  --env GCP={GCLOUD_PROJECT_ID} \
  --env BUCKET_NAME={GCLOUD_PROJECT_ID}-analytics \
  --env SECRET_JSON=/secrets/json/analytics-gcs-writer.json \
  --env SECRET_P12=/secrets/p12/analytics-gcs-writer.p12 \
  --env EMAIL=analytics-gcs-writer@{GCLOUD_PROJECT_ID}.iam.gserviceaccount.com \
  -v {LOCAL_SA_KEY_JSON}:/secrets/json/analytics-gcs-writer.json \
  -v {LOCAL_SA_KEY_P12}:/secrets/p12/analytics-gcs-writer.p12 \
  -p 8080:8080 \
  gcr.io/{GCLOUD_PROJECT_ID}/analytics-endpoint:latest
```

As before, in a different terminal window, submit the follow 2 curl POST requests:

```bash
# Verify v1/event method is working:
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"eventSource\":\"client\",\"eventClass\":\"test\",\"eventType\":\"endpoint_local_containerized\",\"eventTimestamp\":1562599755,\"eventIndex\":6,\"sessionId\":\"f58179a375290599dde17f7c6d546d78\",\"buildVersion\":\"2.0.13\",\"eventEnvironment\":\"testing\",\"eventAttributes\":{\"playerId\": 12345678}}" \
  "http://0.0.0.0:8080/v1/event?key=local_so_does_not_matter&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://0.0.0.0:8080/v1/file?key=local_so_does_not_matter&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"

# To stop the running container:
docker ps # Copy {CONTAINER_ID}
docker kill {CONTAINER_ID}
```

In case the requests were successful, we can now push the container to GCR:

```bash
# Make sure you are in the right project
gcloud config set project {GCLOUD_PROJECT_ID}

# Upload container to Google Container Registry (GCR)
docker push gcr.io/{GCLOUD_PROJECT_ID}/analytics-endpoint:latest

# Verify your image is uploaded
gcloud container images list
```

### (1.3) - Deploying Analytics Endpoint Container onto GKE with Cloud Endpoints

At this point we have a working container hosted in GCR, which GKE can pull containers from. We will now deploy our analytics endpoint on top of GKE. You can check out what your {**K8S_CLUSTER_NAME**, **K8S_CLUSTER_LOCATION**} are [in the Cloud Console](https://console.cloud.google.com/kubernetes/list).

```bash
# Make sure you have the credentials to talk to the right cluster:
gcloud container clusters get-credentials {K8S_CLUSTER_NAME} --zone {K8S_CLUSTER_LOCATION}

# Or if you already do - that you're configured to talk to the right cluster:
kubectl config get-contexts # Copy the correct {K8S_CONTEXT_NAME}
kubectl config use-context {K8S_CONTEXT_NAME}
```

We now first need to make a few edits to our Kubernetes YAML files:

- Update the [deployment.yaml](../../services/k8s/analytics-endpoint/deployment.yaml) file with your {**GCLOUD_PROJECT_ID**}.
- Update the [service.yaml](../../services/k8s/analytics-endpoint/service.yaml) file with your {**ANALYTICS_HOST_IP**}. You can check out what this value is by navigating into [terraform/](https://github.com/improbable/online-services/tree/master/services/terraform) & running `terraform output` (look for **analytics_host**).

**Afterwards** deploy the deployment & service to GKE:

```bash
kubectl apply -f ../../services/k8s/analytics-endpoint
```

Next, [get an API key for your GCP](https://console.cloud.google.com/apis/credentials), which you need to pass via the **key** parameter in the url of your POST request: {GCP_API_KEY}. Note that is is currently [not possible to provision this one programmatically](https://issuetracker.google.com/issues/76227920). Also note that **it takes some time before API keys become fully functional, to be safe wait at least 10 minutes** before attempting the below POST requests.

```bash
# Verify v1/event method is working:
curl --request POST \
  --header "content-type:application/json" \
  --data "{\"eventSource\":\"client\",\"eventClass\":\"test\",\"eventType\":\"endpoint_k8s_containerized\",\"eventTimestamp\":1562599755,\"eventIndex\":6,\"sessionId\":\"f58179a375290599dde17f7c6d546d78\",\"buildVersion\":\"2.0.13\",\"eventEnvironment\":\"testing\",\"eventAttributes\":{\"playerId\": 12345678}}" \
  "http://analytics.endpoints.{GCLOUD_PROJECT_ID}.cloud.goog:80/v1/event?key={GCP_API_KEY}&analytics_environment=testing&event_category=cold&session_id=f58179a375290599dde17f7c6d546d78"

# Verify v1/file method is working:
curl --request POST \
  --header 'content-type:application/json' \
  --data "{\"content_type\":\"text/plain\", \"md5_digest\": \"XKvMhvwrORVuxdX54FQEdg==\"}" \
  "http://analytics.endpoints.{GCLOUD_PROJECT_ID}.cloud.goog:80/v1/file?key={GCP_API_KEY}&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"
```

If both requests succeeded, this means you have now deployed your Analytics Endpoint! :confetti_ball:

## (2) - How to Use the Endpoint

### (2.1) - `/v1/event`

This method enables you to store analytics events in your GCS analytics bucket. The method:

- Accepts JSON dicts (one for each event), either standalone or batched up in lists (recommended).
- Augments JSON events with **batchId**, **eventId**, **receivedTimestamp** & **analyticsEnvironment**.
- Writes received JSON data as newline delimited JSON event files in GCS, which facilitates easy ingestion into BigQuery.
- Determines the files' location in GCS through endpoint URL parameters. These in turn determine whether the events are ingested into native BigQuery storage (vs. GCS as external storage) by default.
- Also accepts non-JSON data.

#### (2.1.1) - URL Parameters

The URL takes 6 parameters:

| Parameter             | Class    | Description |
|-----------------------|----------|-------------|
| key                   | Required | Must be tied to your GCP ([info](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes#create_an_api_key_and_set_an_environment_variable)). |
| analytics_environment | Optional | If omitted, currently defaults to **development**, otherwise must be one of {**testing**, **development**, **staging**, **production**, **live**}. |
| event_category        | Optional | If omitted, currently defaults to **cold**. |
| event_ds              | Optional | If omitted, currently defaults to the current UTC date in **YYYY-MM-DD**. |
| event_time            | Optional | If omitted, currently defaults to current UTC time part, otherwise must be one of {**0-8**, **8-16**, **16-24**}. |
| session_id            | Optional | If omitted, currently defaults to **session-id-not-available**. |

These `<parameters>` (except for **key**) influence where the data ends up in the GCS bucket:

> gs://gcp-analytics-pipeline-events/data\_type={data\_type}/analytics\_environment={analytics\_environment}/event\_category={event\_category}/event\_ds={event\_ds}/event\_time={event\_time}/{session\_id}/{ts\_fmt}\-{int}'

Note that **data_type** is determined automatically and can either be **json** (when valid JSON is POST'ed) or **unknown** (otherwise). The fields **ts_fmt** & **int** are automatically set by the endpoint as well.

Note that the **event_category** parameter is particularly **important**:

- When set to **function** all data contained in the POST request will be **ingested into native BigQuery storage** using the Cloud Function we created when we deployed [the analytics module with Terraform]((https://github.com/improbable/online-services/tree/master/services/terraform)).
- When set to **anything else** all data contained in the POST request will **arrive in GCS**, but will **not by default be ingested into native BigQuery storage**. This data can however still be accessed by BigQuery by using GCS as an external data source.

Note that **function** is a completely arbitrary string, but we have established [GCS notifications to trigger Pub/Sub notifications to our analytics Pub/Sub Topic](https://github.com/improbable/online-services/tree/master/services/terraform/module-analytics/pubsub.tf) whenever files are created on this particular GCS prefix. In this case these notifications invoke our analytics Cloud Function which ingests them into native BigQuery storage. Over-time we can imagine developers extending this setup in new ways: perhaps anything written into **crashdump** (either via **v1/event** or **v1/file**) will trigger a different Cloud Function which can parse a crashdump and write relevant information into BigQuery, or **fps** will be used for high volume frames-per-second events that are subsequently aggregated with a Dataflow (Stream / Batch) script _before_ being written into BigQuery.

#### (2.1.2) - The JSON Event Schema

Each analytics event, which is a JSON dictionary, should adhere to the following JSON schema:

| Key              | Type    | Description |
|------------------|---------|-------------|
| eventEnvironment | string  | One of  {**testing**, **development**, **staging**, **production**, **live**}. |
| eventIndex       | integer | Increments with one with each event per eventSource, allows us to spot missing data. |
| eventSource      | string  | Source of the event, e.g. worker type. |
| eventClass       | string  | A higher order mnemonic classification of events (e.g. session). |
| eventType        | string  | A mnemonic event identifier (e.g. session_start). |
| sessionId        | string  | The session_id, which is unique per client/server session. |
| buildVersion     | string  | Version of the build, should naturally sort from oldest to latest. |
| eventTimestamp   | float   | The timestamp of the event, in unix time. |
| eventAttributes  | dict    | Anything else relating to this particular event will be captured in this attribute as a nested JSON dictionary. |

**Keys should always be camelCase**, whereas values snake_case whenever appropriate. The idea is that all **root keys of the dictionary** are **always present for any event**. Anything custom to a particular event should be nested within eventAttributes. If there is nothing to nest it should be an empty dict (but still present).

In case a server-side event is triggered around a player (vs. AI), always make sure the player_id (or character_id) is captured within eventAttributes. Else you will have no way of knowing which player the event belonged to. For client-side events, as long as we have at least one login event which pairs up the player_id with the client's sessionId, we can always backtrack which other client-side events belonged to a player.

Finally, note that player_id is not a root field of our events, because it will not always be present for any event (e.g. AI induced events, client-side events pre-login, etc.).

### (2.2) - `/v1/file`

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
  "http://analytics.endpoints.{GCLOUD_PROJECT_ID}.cloud.goog:80/v1/file?key={GCP_API_KEY}&analytics_environment=testing&event_category=crashdump-worker&file_parent=parent&file_child=child"

# Grab the signed URL & headers from the returned JSON dictionary (if successful) & write file directly into GCS within 30 minutes:
curl \
  -H 'Content-Type: text/plain' \
  -H 'Content-MD5: XKvMhvwrORVuxdX54FQEdg==' \
  -X PUT "https://storage.googleapis.com/gcp-analytics-pipeline-events/data_type=file/analytics_environment=testing/event_category=crashdump-worker/event_ds=2019-06-18/event_time=8-16/parent/child-451684?GoogleAccessId=event-gcs-writer%40{GCLOUD_PROJECT_ID}.iam.gserviceaccount.com&Expires=1560859391&Signature=tO0bvOzgbF%2F%2FYt%2F%2BHr5L9oH1Y9yQIYMBFIuFyb36L3UhSzalq3%2FRYmto2lguceSoHEtknZQaeI1zDqRwEqfGkPTDGMY9bE1wNR9aT%2F8aAitC0czl6cOPVyJ%2FE1%2B7riEBHXcJyQQSsDMUeJWWT50OKWX4yM961kfJK7c7mv0bvwJPint7Eo5iPTyR9ax57gb4bgSgtFV5MM5c%2FvCIH7%2BuUAiXSbW9CWsA56UJRNf%2BB0YplRtB12VlxWyQlZKpHFrU5EoLQ3vO3YXsQidkjm1it%2BCl1uQptvX%2BZCI7eleEiZANpVX46%2B0MFSXi%2FidMHQSVEF96iGTaFvwzpoiT%2Bj%2F42g%3D%3D" \
  --data-binary '@worker-crashdump-test.gz'
```

## (3) - GKE Debug & Cleanup

The following commands can help you check what is happening with your pods in GKE & potentially debug any issues. Note a pod is generally a group of containers running together. In our case, each pod contains two containers: one running our custom server code & one public Google container that runs everything related to Cloud Endpoints. We are running 3 replicas of our pod together in a single deployment. This means we have 2 x 3 = 6 containers running in our deployment.

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

In case you want remove your workloads (service & deployment) from GKE, you can run the following commands:

```bash
# Obtain list of all your deployments:
kubectl get deployments

# Delete your deployment:
kubectl delete deployment {K8S_DEPLOYMENT_NAME}

# Obtain list of all your services:
kubectl get services

# Delete your service:
kubectl delete service {K8S_SERVICE_NAME}
```
