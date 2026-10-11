resource "google_artifact_registry_repository" "docker" {
  project       = var.project_id
  location      = var.region
  repository_id = "weather-platform"

  description = "Docker images for the weather data platform."
  format      = "DOCKER"
}