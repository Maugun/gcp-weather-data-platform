locals {
  workload_service_accounts = toset([
    "open-meteo-ingestion",
    "dataform-runner",
  ])
}

resource "google_service_account" "workloads" {
  for_each = local.workload_service_accounts

  project      = var.project_id
  account_id   = each.value
  display_name = each.value
}