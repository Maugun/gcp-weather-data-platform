locals {
  dataform_service_agent   = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  datastream_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-datastream.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "dataform_service_agent_user" {
  service_account_id = google_service_account.workloads["dataform-runner"].name

  role   = "roles/iam.serviceAccountUser"
  member = local.dataform_service_agent
}

resource "google_service_account_iam_member" "dataform_service_agent_token_creator" {
  service_account_id = google_service_account.workloads["dataform-runner"].name

  role   = "roles/iam.serviceAccountTokenCreator"
  member = local.dataform_service_agent
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
  secret_id = google_secret_manager_secret.datastream_db_password.secret_id

  role   = "roles/secretmanager.secretAccessor"
  member = local.datastream_service_agent
}
