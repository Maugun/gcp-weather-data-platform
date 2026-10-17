locals {
  bigquery_dataset_iam_grants = {
    dataform_raw_viewer = {
      dataset_key         = "weather_raw"
      role                = "roles/bigquery.dataViewer"
      workload_account_id = "dataform-runner"
    }
    dataform_staging_editor = {
      dataset_key         = "weather_staging"
      role                = "roles/bigquery.dataEditor"
      workload_account_id = "dataform-runner"
    }
    dataform_curated_editor = {
      dataset_key         = "weather_curated"
      role                = "roles/bigquery.dataEditor"
      workload_account_id = "dataform-runner"
    }
    dataform_curated_governance_manager = {
      dataset_key         = "weather_curated"
      role                = google_project_iam_custom_role.bigquery_curated_governance_manager.name
      workload_account_id = "dataform-runner"
    }
    dataform_assertions_editor = {
      dataset_key         = "dataform_assertions"
      role                = "roles/bigquery.dataEditor"
      workload_account_id = "dataform-runner"
    }
    bigquery_s3_transfer_editor = {
      dataset_key         = "weather_raw"
      role                = "roles/bigquery.dataEditor"
      workload_account_id = "bigquery-s3-transfer"
    }
  }

  project_iam_grants = {
    dataform_runner_job_user = {
      role                = "roles/bigquery.jobUser"
      workload_account_id = "dataform-runner"
    }
    weather_fr_analyst_job_user = {
      role                = "roles/bigquery.jobUser"
      workload_account_id = "weather-fr-analyst"
    }
    weather_api_cloud_sql_client = {
      role                = "roles/cloudsql.client"
      workload_account_id = "weather-api"
    }
    bigquery_s3_transfer_job_user = {
      role                = "roles/bigquery.jobUser"
      workload_account_id = "bigquery-s3-transfer"
    }
  }
}

resource "google_bigquery_dataset_iam_member" "workload_dataset_grants" {
  for_each = local.bigquery_dataset_iam_grants

  project    = var.project_id
  dataset_id = google_bigquery_dataset.datasets[each.value.dataset_key].dataset_id
  role       = each.value.role
  member     = "serviceAccount:${google_service_account.workloads[each.value.workload_account_id].email}"
}

resource "google_project_iam_member" "workload_project_grants" {
  for_each = local.project_iam_grants

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workloads[each.value.workload_account_id].email}"
}

resource "google_project_iam_custom_role" "bigquery_curated_governance_manager" {
  project     = var.project_id
  role_id     = "bigqueryCuratedGovernanceManager"
  title       = "BigQuery Curated Governance Manager"
  description = "Manage row access policies, table-level access, and column classifications for Dataform-managed curated tables."
  permissions = [
    "bigquery.rowAccessPolicies.create",
    "bigquery.rowAccessPolicies.setIamPolicy",
    "bigquery.rowAccessPolicies.update",
    "bigquery.tables.setIamPolicy",
    "bigquery.tables.setCategory",
  ]
}

resource "google_secret_manager_secret_iam_member" "weather_api_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets["weather_db_password"].secret_id

  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.workloads["weather-api"].email}"
}
