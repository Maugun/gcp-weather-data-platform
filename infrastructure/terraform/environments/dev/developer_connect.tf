resource "google_developer_connect_connection" "github_dataform" {
  project       = var.project_id
  location      = var.dataform_region
  connection_id = "github-dataform"

  github_config {
    github_app = "DATAFORM"
  }
}

resource "google_developer_connect_git_repository_link" "weather_dataform" {
  project                = var.project_id
  location               = var.dataform_region
  parent_connection      = google_developer_connect_connection.github_dataform.connection_id
  git_repository_link_id = "Maugun-gcp-weather-dataform"
  clone_uri              = "https://github.com/Maugun/gcp-weather-dataform.git"
}
