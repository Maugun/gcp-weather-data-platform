terraform {
  backend "gcs" {
    bucket = "de-gcp-lab-terraform-state"
    prefix = "gcp-weather-data-platform/dev"
  }
}