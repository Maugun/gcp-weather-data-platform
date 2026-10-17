resource "google_project_service" "cloud_resource_manager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "data_catalog" {
  project = var.project_id
  service = "datacatalog.googleapis.com"

  disable_on_destroy = false
}
