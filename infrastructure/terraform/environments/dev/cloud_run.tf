locals {
  open_meteo_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/open-meteo:${var.open_meteo_image_tag}"
}

resource "google_cloud_run_v2_job" "open_meteo_ingestion" {
  name     = "open-meteo-ingestion"
  location = var.region
  project  = var.project_id

  deletion_protection = false

  template {
    task_count = 1

    template {
      service_account = google_service_account.workloads["open-meteo-ingestion"].email

      max_retries = 3
      timeout     = "600s"

      containers {
        name  = "open-meteo-ingestion-1"
        image = local.open_meteo_image

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "BUCKET_NAME"
          value = "de-gcp-lab-raw"
        }

        env {
          name  = "LATITUDE"
          value = "48.8566"
        }

        env {
          name  = "LONGITUDE"
          value = "2.3522"
        }

        env {
          name  = "LOCATION_NAME"
          value = "Paris"
        }

        env {
          name  = "TIMEZONE"
          value = "Europe/Paris"
        }
      }
    }
  }
}