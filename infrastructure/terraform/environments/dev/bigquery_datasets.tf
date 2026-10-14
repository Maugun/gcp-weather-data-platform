locals {
  bigquery_datasets = toset([
    "weather_raw",
    "weather_staging",
    "weather_curated",
    "dataform_assertions",
  ])
}

resource "google_bigquery_dataset" "datasets" {
  for_each = local.bigquery_datasets

  dataset_id = each.value
  location   = var.data_location
}