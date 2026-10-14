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

variable "weather_api_image_tag" {
  description = "Docker image tag deployed for the Weather API."
  type        = string
}

variable "aws_s3_access_key_id" {
  description = "AWS access key ID used by BigQuery Data Transfer Service"
  type        = string
  sensitive   = true
}
