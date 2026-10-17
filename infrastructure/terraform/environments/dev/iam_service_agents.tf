locals {
  dataform_service_agent   = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  datastream_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-datastream.iam.gserviceaccount.com"

  dataform_service_account_grants = {
    dataform_service_agent_user          = "roles/iam.serviceAccountUser"
    dataform_service_agent_token_creator = "roles/iam.serviceAccountTokenCreator"
  }
}

resource "google_service_account_iam_member" "dataform_runner_grants" {
  for_each = local.dataform_service_account_grants

  service_account_id = google_service_account.workloads["dataform-runner"].name
  role               = each.value
  member             = local.dataform_service_agent
}

resource "google_project_iam_member" "dataform_service_agent_developer_connect" {
  for_each = toset([
    "roles/developerconnect.gitProxyUser",
    "roles/developerconnect.tokenAccessor",
  ])

  project = var.project_id
  role    = each.value
  member  = local.dataform_service_agent
}

resource "google_secret_manager_secret_iam_member" "datastream_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets["datastream_db_password"].secret_id

  role   = "roles/secretmanager.secretAccessor"
  member = local.datastream_service_agent
}
