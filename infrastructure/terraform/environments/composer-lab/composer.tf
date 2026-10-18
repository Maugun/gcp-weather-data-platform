resource "google_composer_environment" "weather" {
  provider = google-beta

  project = var.project_id
  name    = "weather-airflow"
  region  = var.region

  labels = {
    managed_by = "terraform"
    purpose    = "portfolio"
  }

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    software_config {
      # Pin the image so future Composer releases cannot change this environment implicitly.
      image_version = "composer-3-airflow-3.3.1-build.4"
    }

    node_config {
      service_account = google_service_account.airflow_orchestrator.name
    }
  }

  depends_on = [
    google_project_service.composer,
    google_project_iam_member.airflow_project_grants,
  ]
}
