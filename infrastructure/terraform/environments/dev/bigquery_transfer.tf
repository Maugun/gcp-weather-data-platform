resource "google_bigquery_data_transfer_config" "weather_s3_history" {
  project                = var.project_id
  location               = "europe"
  display_name           = "Weather Historical S3"
  data_source_id         = "amazon_s3"
  destination_dataset_id = google_bigquery_dataset.datasets["weather_raw"].dataset_id

  service_account_name = google_service_account.workloads["bigquery-s3-transfer"].email

  data_refresh_window_days = 0
  disabled                 = false

  params = {
    destination_table_name_template = google_bigquery_table.s3_historical_weather.table_id
    data_path                       = "s3://de-gcp-lab-weather-history/historical/*.parquet"
    access_key_id                   = var.aws_s3_access_key_id
    file_format                     = "PARQUET"
    write_disposition               = "WRITE_APPEND"

    allow_jagged_rows     = "false"
    allow_quoted_newlines = "false"
    field_delimiter       = ","
    ignore_unknown_values = "false"
    max_bad_records       = "0"
    skip_leading_rows     = "0"
  }

  sensitive_params {
    secret_access_key_wo = (
      ephemeral.google_secret_manager_secret_version.aws_s3_secret_access_key.secret_data
    )

    secret_access_key_wo_version = 1
  }

  schedule_options {
    disable_auto_scheduling = true
  }
}