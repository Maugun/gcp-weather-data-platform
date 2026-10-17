locals {
  github_actions_plan_roles = toset([
    "roles/apigateway.editor",
    "roles/artifactregistry.reader",
    "roles/browser",
    "roles/bigquery.metadataViewer",
    "roles/bigquery.user",
    "roles/dataform.viewer",
    "roles/datacatalog.viewer",
    "roles/datastream.viewer",
    "roles/developerconnect.viewer",
    "roles/iam.securityReviewer",
    "roles/iam.serviceAccountViewer",
    "roles/iam.workloadIdentityPoolViewer",
    "roles/run.viewer",
  ])

  github_actions_service_account_users = {
    github_actions_open_meteo_user          = "open-meteo-ingestion"
    github_actions_weather_api_gateway_user = "weather-api-gateway"
    github_actions_weather_api_user         = "weather-api"
  }

  github_actions_secret_grants = {
    github_actions_weather_db_viewer = {
      secret_key = "weather_db_password"
      role       = "roles/secretmanager.viewer"
    }
    github_actions_datastream_db_viewer = {
      secret_key = "datastream_db_password"
      role       = "roles/secretmanager.viewer"
    }
    github_actions_aws_s3_secret_viewer = {
      secret_key = "aws_s3_secret_access_key"
      role       = "roles/secretmanager.viewer"
    }
    github_actions_aws_s3_secret_accessor = {
      secret_key = "aws_s3_secret_access_key"
      role       = "roles/secretmanager.secretAccessor"
    }
  }
}

resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions.name

  role = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_project_iam_member" "github_actions_plan" {
  for_each = local.github_actions_plan_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_artifact_registry_repository_iam_member" "github_actions_writer" {
  project    = google_artifact_registry_repository.docker.project
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_cloud_run_v2_job_iam_member" "github_actions_developer" {
  project  = google_cloud_run_v2_job.open_meteo_ingestion.project
  location = google_cloud_run_v2_job.open_meteo_ingestion.location
  name     = google_cloud_run_v2_job.open_meteo_ingestion.name

  role   = "roles/run.developer"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_member" "github_actions_workload_users" {
  for_each = local.github_actions_service_account_users

  service_account_id = google_service_account.workloads[each.value].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_secret_manager_secret_iam_member" "github_actions_secrets" {
  for_each = local.github_actions_secret_grants

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_key].secret_id
  role      = each.value.role
  member    = "serviceAccount:${google_service_account.github_actions.email}"
}
