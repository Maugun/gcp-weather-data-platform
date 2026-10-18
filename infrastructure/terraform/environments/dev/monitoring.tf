locals {
  dataform_failed_workflow_filter = <<-EOT
    resource.type = "dataform.googleapis.com/Repository"
    resource.labels.repository_id = "weather-dataform"
    jsonPayload.@type = "type.googleapis.com/google.cloud.dataform.logging.v1.WorkflowInvocationCompletionLogEntry"
    jsonPayload.terminalState = "FAILED"
  EOT

  open_meteo_job_error_filter = <<-EOT
    resource.type = "cloud_run_job"
    resource.labels.job_name = "open-meteo-ingestion"
    resource.labels.location = "europe-west1"
    severity >= ERROR
  EOT

  api_gateway_5xx_filter = join(" AND ", [
    "resource.type = \"apigateway.googleapis.com/Gateway\"",
    "resource.labels.gateway_id = \"weather-api-gateway\"",
    "metric.type = \"apigateway.googleapis.com/proxy/request_count\"",
    "metric.labels.response_code_class = \"5xx\"",
  ])

  datastream_unsupported_events_filter = join(" AND ", [
    "resource.type = \"datastream.googleapis.com/Stream\"",
    "resource.labels.stream_id = \"weather-postgres-to-bigquery\"",
    "metric.type = \"datastream.googleapis.com/stream/unsupported_event_count\"",
  ])

  api_gateway_request_filter = join(" AND ", [
    "resource.type = \"apigateway.googleapis.com/Gateway\"",
    "resource.labels.gateway_id = \"weather-api-gateway\"",
    "metric.type = \"apigateway.googleapis.com/proxy/request_count\"",
  ])

  open_meteo_job_execution_filter = join(" AND ", [
    "resource.type = \"cloud_run_job\"",
    "resource.labels.job_name = \"open-meteo-ingestion\"",
    "metric.type = \"run.googleapis.com/job/completed_execution_count\"",
  ])

  datastream_freshness_filter = join(" AND ", [
    "resource.type = \"datastream.googleapis.com/Stream\"",
    "resource.labels.stream_id = \"weather-postgres-to-bigquery\"",
    "metric.type = \"datastream.googleapis.com/stream/freshness\"",
  ])

  weather_operations_dashboard = {
    displayName = "Weather Platform Operations"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "API Gateway requests by response class"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = local.api_gateway_request_filter
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
              plotType       = "LINE"
              targetAxis     = "Y1"
              legendTemplate = "$${metric.labels.response_code_class}"
            }]
            yAxis = {
              label = "Requests per minute"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Open-Meteo Cloud Run Job completed executions"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = local.open_meteo_job_execution_filter
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
              plotType       = "LINE"
              targetAxis     = "Y1"
              legendTemplate = "$${metric.labels.result}"
            }]
            yAxis = {
              label = "Completed executions"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Datastream freshness"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = local.datastream_freshness_filter
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
              plotType   = "LINE"
              targetAxis = "Y1"
            }]
            yAxis = {
              label = "Seconds"
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Datastream unsupported events"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = local.datastream_unsupported_events_filter
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
              plotType   = "LINE"
              targetAxis = "Y1"
            }]
            yAxis = {
              label = "Events per minute"
              scale = "LINEAR"
            }
          }
        },
      ]
    }
  }
}

resource "google_monitoring_notification_channel" "weather_alert_email" {
  project      = var.project_id
  display_name = "Weather platform alerts"
  type         = "email"
  labels = {
    email_address = var.monitoring_alert_email
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "dataform_failed_workflow" {
  project      = var.project_id
  display_name = "Dataform workflow failed"
  combiner     = "OR"
  enabled      = true

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  conditions {
    display_name = "A weather-dataform workflow invocation failed"

    condition_matched_log {
      filter = local.dataform_failed_workflow_filter
    }
  }

  documentation {
    content = "A workflow invocation in the weather-dataform repository failed. Review its invocation details and assertion results in Dataform."
  }

  notification_channels = [google_monitoring_notification_channel.weather_alert_email.name]

  user_labels = {
    severity   = "warning"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "open_meteo_job_error_logs" {
  project      = var.project_id
  display_name = "Open-Meteo Cloud Run Job error logs"
  combiner     = "OR"
  enabled      = true

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  conditions {
    display_name = "An error-level log was emitted by open-meteo-ingestion"

    condition_matched_log {
      filter = local.open_meteo_job_error_filter
    }
  }

  documentation {
    content = "An error-level log was emitted by the open-meteo-ingestion Cloud Run Job. Review the execution logs and task status."
  }

  notification_channels = [google_monitoring_notification_channel.weather_alert_email.name]

  user_labels = {
    severity   = "warning"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "api_gateway_5xx" {
  project      = var.project_id
  display_name = "Weather API Gateway returned 5xx"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "At least one 5xx response in a five-minute window"

    condition_threshold {
      filter          = local.api_gateway_5xx_filter
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content = "The Weather API Gateway recorded at least one HTTP 5xx response in a five-minute window. Check API Gateway request logs and the private weather-api Cloud Run service logs."
  }

  notification_channels = [google_monitoring_notification_channel.weather_alert_email.name]

  user_labels = {
    severity   = "warning"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "datastream_unsupported_events" {
  project      = var.project_id
  display_name = "Datastream unsupported events detected"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "At least one unsupported event in a five-minute window"

    condition_threshold {
      filter          = local.datastream_unsupported_events_filter
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content = "Datastream reported an event that it could not process. Inspect the stream's unsupported-event details, including the object and error code."
  }

  notification_channels = [google_monitoring_notification_channel.weather_alert_email.name]

  user_labels = {
    severity   = "warning"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_dashboard" "weather_operations" {
  project        = var.project_id
  dashboard_json = jsonencode(local.weather_operations_dashboard)

  depends_on = [google_project_service.monitoring]
}
