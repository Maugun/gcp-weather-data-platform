locals {
  weather_api_service_iam_grants = {
    github_actions_weather_api_developer = {
      role   = "roles/run.developer"
      member = "serviceAccount:${google_service_account.github_actions.email}"
    }
    weather_api_gateway_invoker = {
      role   = "roles/run.invoker"
      member = "serviceAccount:${google_service_account.workloads["weather-api-gateway"].email}"
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "weather_api_grants" {
  for_each = local.weather_api_service_iam_grants

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.weather_api.name
  role     = each.value.role
  member   = each.value.member
}
