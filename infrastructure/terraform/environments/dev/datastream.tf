resource "google_datastream_connection_profile" "weather_postgres" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "weather-postgres"
  display_name          = "Weather PostgreSQL"

  postgresql_profile {
    hostname = "34.53.174.126"
    port     = 5432
    username = "datastream"
    database = "postgres"

    secret_manager_stored_password = "projects/${data.google_project.current.number}/secrets/${google_secret_manager_secret.datastream_db_password.secret_id}/versions/latest"
  }

  depends_on = [
    google_secret_manager_secret_iam_member.datastream_secret_accessor,
  ]
}

resource "google_datastream_connection_profile" "weather_bigquery" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "weather-bigquery"
  display_name          = "Weather BigQuery"

  bigquery_profile {}
}

resource "google_datastream_stream" "weather_postgres_to_bigquery" {
  project      = var.project_id
  location     = var.region
  stream_id    = "weather-postgres-to-bigquery"
  display_name = "Weather PostgreSQL to BigQuery"

  lifecycle {
    ignore_changes = [
      desired_state,
    ]
  }

  source_config {
    source_connection_profile = google_datastream_connection_profile.weather_postgres.id

    postgresql_source_config {
      publication      = "weather_datastream_publication"
      replication_slot = "weather_datastream_slot"

      include_objects {
        postgresql_schemas {
          schema = "public"

          postgresql_tables {
            table = "weather_stations"
          }

          postgresql_tables {
            table = "weather_observations"
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.weather_bigquery.id

    bigquery_destination_config {
      data_freshness = "900s"

      single_target_dataset {
        dataset_id = google_bigquery_dataset.datasets["weather_raw"].id
      }

      merge {}
    }
  }

  backfill_all {}
}