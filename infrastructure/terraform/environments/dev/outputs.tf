output "weather_raw_dataset_id" {
  description = "BigQuery RAW dataset ID."
  value       = google_bigquery_dataset.datasets["weather_raw"].dataset_id
}

output "weather_raw_resource_id" {
  description = "Terraform resource ID for the RAW dataset."
  value       = google_bigquery_dataset.datasets["weather_raw"].id
}