resource "google_secret_manager_secret" "weather_db_password" {
  project   = var.project_id
  secret_id = "weather-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "datastream_db_password" {
  project   = var.project_id
  secret_id = "datastream-db-password"

  replication {
    auto {}
  }
}