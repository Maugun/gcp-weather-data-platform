data "google_project" "current" {
  project_id = var.project_id
}

locals {
  dataform_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "dataform_runner_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.workloads["dataform-runner"].email}"
}

resource "google_bigquery_dataset_iam_member" "dataform_raw_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.datasets["weather_raw"].dataset_id

  role   = "roles/bigquery.dataViewer"
  member = "serviceAccount:${google_service_account.workloads["dataform-runner"].email}"
}

resource "google_bigquery_dataset_iam_member" "dataform_staging_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.datasets["weather_staging"].dataset_id

  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.workloads["dataform-runner"].email}"
}

resource "google_bigquery_dataset_iam_member" "dataform_assertions_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.datasets["dataform_assertions"].dataset_id

  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.workloads["dataform-runner"].email}"
}

resource "google_service_account_iam_member" "dataform_service_agent_user" {
  service_account_id = google_service_account.workloads["dataform-runner"].name

  role   = "roles/iam.serviceAccountUser"
  member = local.dataform_service_agent
}

resource "google_service_account_iam_member" "dataform_service_agent_token_creator" {
  service_account_id = google_service_account.workloads["dataform-runner"].name

  role   = "roles/iam.serviceAccountTokenCreator"
  member = local.dataform_service_agent
}

resource "google_secret_manager_secret_iam_member" "weather_api_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.weather_db_password.secret_id

  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.workloads["weather-api"].email}"
}

resource "google_project_iam_member" "weather_api_cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"

  member = "serviceAccount:${google_service_account.workloads["weather-api"].email}"
}

resource "google_cloud_run_v2_service_iam_member" "weather_api_gateway_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.weather_api.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.workloads["weather-api-gateway"].email}"
}

resource "google_secret_manager_secret_iam_member" "github_actions_weather_db_viewer" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.weather_db_password.secret_id

  role   = "roles/secretmanager.viewer"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}