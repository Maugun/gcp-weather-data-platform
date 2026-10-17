locals {
  secret_definitions = {
    weather_db_password      = "weather-db-password"
    datastream_db_password   = "datastream-db-password"
    aws_s3_secret_access_key = "aws-s3-secret-access-key"
  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each = local.secret_definitions

  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }
}

ephemeral "google_secret_manager_secret_version" "aws_s3_secret_access_key" {
  project = var.project_id
  secret  = google_secret_manager_secret.secrets["aws_s3_secret_access_key"].secret_id
  version = "latest"
}
