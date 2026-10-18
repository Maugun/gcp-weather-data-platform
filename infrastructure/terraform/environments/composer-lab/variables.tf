variable "project_id" {
  description = "GCP project containing the weather platform and the Composer lab."
  type        = string
}

variable "github_repository" {
  description = "GitHub owner/repository allowed to deploy Airflow DAGs with Workload Identity Federation."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use the owner/repository format."
  }
}

variable "region" {
  description = "Region where the temporary Cloud Composer environment runs."
  type        = string
  default     = "europe-west1"
}

variable "raw_bucket_name" {
  description = "Existing GCS bucket containing Open-Meteo RAW files."
  type        = string
  default     = "de-gcp-lab-raw"
}

variable "cloud_run_job_name" {
  description = "Existing Cloud Run Job triggered by the Airflow DAG."
  type        = string
  default     = "open-meteo-ingestion"
}

variable "dataform_region" {
  description = "Region where the Dataform repository runs."
  type        = string
  default     = "europe-west9"
}

variable "dataform_repository_id" {
  description = "Existing Dataform repository invoked by the Airflow DAG."
  type        = string
  default     = "weather-dataform"
}

variable "dataform_runner_account_id" {
  description = "Account ID of the existing Dataform runtime service account."
  type        = string
  default     = "dataform-runner"
}
