resource "google_bigquery_table" "s3_historical_weather" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.datasets["weather_raw"].dataset_id
  table_id   = "s3_historical_weather"

  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }

  clustering = ["station_id"]

  schema = file("${path.module}/../../schemas/s3_historical_weather.json")
}