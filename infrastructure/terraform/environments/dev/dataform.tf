resource "google_dataform_repository" "weather" {
  provider = google-beta

  project = var.project_id
  region  = var.dataform_region
  name    = "ecommerce-dataform"
}