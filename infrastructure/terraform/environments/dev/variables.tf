variable "project_id" {
  description = "GCP project hosting the weather data platform."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "europe-west1"
}

variable "data_location" {
  description = "Location used for BigQuery datasets and data storage."
  type        = string
  default     = "EU"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "dataform_region" {
  description = "GCP region used by Dataform."
  type        = string
  default     = "europe-west9"
}

variable "open_meteo_image_tag" {
  description = "Docker image tag deployed for the Open-Meteo ingestion job."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to authenticate to GCP."
  type        = string
}