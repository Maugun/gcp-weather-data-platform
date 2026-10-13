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

resource "google_secret_manager_secret" "aws_s3_secret_access_key" {
  project   = var.project_id
  secret_id = "aws-s3-secret-access-key"

  replication {
    auto {}
  }
}

ephemeral "google_secret_manager_secret_version" "aws_s3_secret_access_key" {
  project = var.project_id
  secret  = google_secret_manager_secret.aws_s3_secret_access_key.secret_id
  version = "latest"
}