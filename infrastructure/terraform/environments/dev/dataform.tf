resource "google_dataform_repository" "weather_git" {
  provider = google-beta

  project         = var.project_id
  region          = "europe-west9"
  name            = "weather-dataform"
  service_account = google_service_account.workloads["dataform-runner"].email

  git_remote_settings {
    url                 = "https://github.com/Maugun/gcp-weather-dataform.git"
    default_branch      = "master"
    git_repository_link = google_developer_connect_git_repository_link.weather_dataform.name
  }
}