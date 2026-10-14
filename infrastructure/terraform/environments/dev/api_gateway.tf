resource "google_api_gateway_api" "weather" {
  provider = google-beta
  project  = var.project_id

  api_id = "weather-api"
}

resource "google_api_gateway_api_config" "weather_v3" {
  provider = google-beta
  project  = var.project_id

  api                  = google_api_gateway_api.weather.api_id
  api_config_id_prefix = "weather-api-"

  gateway_config {
    backend_config {
      google_service_account = google_service_account.workloads["weather-api-gateway"].email
    }
  }

  openapi_documents {
    document {
      path = "openapi.yaml"

      contents = base64encode(
        replace(
          file("${path.module}/../../../../api/weather-api/openapi.yaml"),
          "\r\n",
          "\n"
        )
      )
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "weather" {
  provider = google-beta
  project  = var.project_id
  region   = var.region

  gateway_id = "weather-api-gateway"
  api_config = google_api_gateway_api_config.weather_v3.id
}