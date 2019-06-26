
data "archive_file" "cloud_function_analytics" {
  type        = "zip"
  output_path = "${path.module}/../../python/analytics-pipeline/cloud-function-analytics.zip"

  source {
    content  = "${file("${path.module}/../../python/analytics-pipeline/src/main.py")}"
    filename = "main.py"
  }

  source {
    content  = "${file("${path.module}/../../python/analytics-pipeline/src/requirements-function.txt")}"
    filename = "requirements.txt"
  }

  source {
    content  = "${file("${path.module}/../../python/analytics-pipeline/src/shared/__init__.py")}"
    filename = "shared/__init__.py"
  }

  source {
    content  = "${file("${path.module}/../../python/analytics-pipeline/src/shared/bigquery.py")}"
    filename = "shared/bigquery.py"
  }

  source {
    content  = "${file("${path.module}/../../python/analytics-pipeline/src/shared/parser.py")}"
    filename = "shared/parser.py"
  }

}
