locals {
  workload_service_accounts = {
    "open-meteo-ingestion" = "Open Meteo Ingestion"
    "dataform-runner"      = "Dataform Runner"
    "weather-api"          = "Weather API"
    "weather-api-gateway"  = "Weather API Gateway"
  }
}

resource "google_service_account" "workloads" {
  for_each = local.workload_service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = each.value
}