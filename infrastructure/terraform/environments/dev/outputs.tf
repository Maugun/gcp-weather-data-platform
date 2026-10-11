output "weather_raw_dataset_id" {
  description = "BigQuery RAW dataset ID."
  value       = google_bigquery_dataset.datasets["weather_raw"].dataset_id
}

output "weather_raw_resource_id" {
  description = "Terraform resource ID for the RAW dataset."
  value       = google_bigquery_dataset.datasets["weather_raw"].id
}

output "github_workload_identity_provider" {
  description = "Workload Identity Provider used by GitHub Actions."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_service_account_email" {
  description = "Service Account used by GitHub Actions."
  value       = google_service_account.github_actions.email
}

output "open_meteo_image_tag" {
  description = "Git commit SHA of the currently deployed Open-Meteo image."
  value       = var.open_meteo_image_tag
}