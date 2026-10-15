locals {
  workload_service_accounts = {
    "open-meteo-ingestion" = "Open Meteo Ingestion"
    "dataform-runner"      = "Dataform Runner"
    "weather-api"          = "Weather API"
    "weather-api-gateway"  = "Weather API Gateway"
    "bigquery-s3-transfer" = "BigQuery S3 Transfer"
    "weather-fr-analyst"   = "Weather France Analyst (RLS test)"
  }
}

resource "google_service_account" "workloads" {
  for_each = local.workload_service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = each.value
}
