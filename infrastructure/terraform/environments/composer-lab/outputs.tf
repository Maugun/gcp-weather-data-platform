output "composer_environment_name" {
  description = "Name of the Cloud Composer environment used for the lab."
  value       = google_composer_environment.weather.name
}

output "airflow_service_account_email" {
  description = "Identity used by Airflow DAG tasks to call Google Cloud APIs."
  value       = google_service_account.airflow_orchestrator.email
}
