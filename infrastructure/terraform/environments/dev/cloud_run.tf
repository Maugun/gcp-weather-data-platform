locals {
  open_meteo_image            = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/open-meteo:${var.open_meteo_image_tag}"
  weather_api_bootstrap_image = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/weather-api:${var.weather_api_image_tag}"
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

resource "google_cloud_run_v2_service" "weather_api" {
  project  = var.project_id
  name     = "weather-api"
  location = var.region

  deletion_protection = true

  template {
    service_account = google_service_account.workloads["weather-api"].email

    containers {
      image = local.weather_api_bootstrap_image

      ports {
        container_port = 8080
      }

      env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = "${var.project_id}:${var.region}:weather-postgres"
      }

      env {
        name  = "DB_NAME"
        value = "postgres"
      }

      env {
        name  = "DB_USER"
        value = "weather_app"
      }

      env {
        name = "DB_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secrets["weather_db_password"].secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }

        cpu_idle          = true
        startup_cpu_boost = true
      }

      startup_probe {
        failure_threshold = 1
        period_seconds    = 240
        timeout_seconds   = 240

        tcp_socket {
          port = 8080
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.workload_project_grants["weather_api_cloud_sql_client"],
    google_secret_manager_secret_iam_member.weather_api_secret_accessor,
  ]

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      build_config,
    ]
  }
}
