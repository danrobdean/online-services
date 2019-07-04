## BigQuery: GCS as External Data Source

This section outlines how our newline delimited JSON events in GCS can be instantly accessed with BigQuery, and parsed using SQL statements.

### (0) - Using Permanent BigQuery Tables

Go to your BigQuery overview, click on a dataset & then **Create Table**. Fill out form & hit **Create table** again, example input:

**Native BigQuery Table** (static import):

- Table name: **events\_gcs\_native\_static**
- Table type: **Native** - which imports the data "as of now" into a static table in native BigQuery storage.

**External BigQuery Table** (live link):

- Table name: **events\_gcs\_external\_live**
- Table type: **External** to establish a live link between GCS & BigQuery.

> Note that querying an External table will dynamically (re-)parse all files present in your GCS URI. Therefore, as the number of files in your path grows over-time, queries will take longer to execute. An upcoming feature will be the support of Hive partitioning paths, which means that when using External tables, you can further filter (beyond the GCS URI) which files should be taken into consideration, by adding path_keys into the WHERE clause of your SQL statement (e.g. `SELECT * FROM table WHERE event_ds = '2019-06-05'` will only look at files matching both the GCS URI and ../event\_ds=2019-06-05/..

For both table types the following settings can be identical:

- GCS URI: **gs://gcp-analytics-pipeline-events/data\_type=json/analytics\_environment=testing/event\_category=cold/***
- Schema: **eventIndex:INTEGER,buildVersion:STRING,eventType:STRING,sessionId:STRING,eventEnvironment:STRING,eventSource:STRING,eventTimestamp:TIMESTAMP,eventAttributes:STRING,eventClass:STRING,receivedTimestamp:TIMESTAMP**

The following usage notes also apply to both table types:

- Values denoted in the **schema** that are **not present in the event** JSON dictionary in GCS will be shown as **NULL in BigQuery**.
- If you want to omit importing certain event attributes by excluding them from the schema, you **must** select **"Ignore unknown values"**.

_Tip: The GCS file path [accepts wildcards](https://cloud.google.com/bigquery/external-data-cloud-storage#wildcard-support)._

[More information..](https://cloud.google.com/bigquery/external-data-cloud-storage#permanent-tables)

### (1) - Using Temporary BigQuery Tables

Via the Command Line you will be able to instantly run queries on your events data in GCS. Each query will first create a temporary table which contains all data found in the given GCS URI. Afterwards your SQL statement is executed & results printed to the console, after which the temporary table is deleted.

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

[More information..](https://cloud.google.com/bigquery/external-data-cloud-storage#temporary-tables)
