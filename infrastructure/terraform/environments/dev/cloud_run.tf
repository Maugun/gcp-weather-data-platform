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
        name = "open-meteo-ingestion-1"

        image = "europe-west1-docker.pkg.dev/de-gcp-lab/cloud-run-source-deploy/open-meteo-ingestion@sha256:aec14aeb243af54bcf72babb3aab471e9751c937ed0ea6b5b7e23f8b0c1d7e28"

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