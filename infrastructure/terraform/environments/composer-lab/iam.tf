locals {
  airflow_project_grants = toset([
    "roles/composer.worker",
    "roles/bigquery.jobUser",
    "roles/logging.viewer",
  ])
}

resource "google_project_iam_member" "airflow_project_grants" {
  for_each = local.airflow_project_grants

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_bigquery_dataset_iam_member" "airflow_weather_raw_editor" {
  project    = var.project_id
  dataset_id = "weather_raw"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_storage_bucket_iam_member" "airflow_raw_object_viewer" {
  bucket = var.raw_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_cloud_run_v2_job_iam_member" "airflow_open_meteo_executor" {
  project  = var.project_id
  location = var.region
  name     = var.cloud_run_job_name

  role   = "roles/run.jobsExecutorWithOverrides"
  member = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_project_iam_custom_role" "dataform_workflow_invoker" {
  project     = var.project_id
  role_id     = "dataformWorkflowInvoker"
  title       = "Dataform Workflow Invoker"
  description = "Compile and execute workflows in the weather Dataform repository."
  permissions = [
    "dataform.compilationResults.create",
    "dataform.compilationResults.get",
    "dataform.repositories.get",
    "dataform.workspaces.get",
    "dataform.workflowInvocations.create",
    "dataform.workflowInvocations.get",
  ]
}

resource "google_dataform_repository_iam_member" "airflow_workflow_invoker" {
  provider = google-beta

  project    = var.project_id
  region     = var.dataform_region
  repository = var.dataform_repository_id

  role   = google_project_iam_custom_role.dataform_workflow_invoker.name
  member = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_service_account_iam_member" "airflow_dataform_runner_user" {
  service_account_id = data.google_service_account.dataform_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

resource "google_project_iam_custom_role" "github_actions_composer_environment_reader" {
  project     = var.project_id
  role_id     = "githubActionsComposerEnvironmentReader"
  title       = "GitHub Actions Composer Environment Reader"
  description = "Read Cloud Composer environment metadata so GitHub Actions can discover its DAG bucket."
  permissions = [
    "composer.environments.get",
  ]
}

resource "google_project_iam_member" "github_actions_composer_environment_reader" {
  project = var.project_id
  role    = google_project_iam_custom_role.github_actions_composer_environment_reader.name
  member  = "serviceAccount:${google_service_account.github_actions_composer_dag_deployer.email}"
}

resource "google_project_iam_custom_role" "github_actions_composer_dag_deployer" {
  project     = var.project_id
  role_id     = "githubActionsComposerDagDeployer"
  title       = "GitHub Actions Composer DAG Deployer"
  description = "Upload and update DAG files in a Cloud Composer environment bucket."
  permissions = [
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.list",
  ]
}

locals {
  composer_dag_bucket_name = split(
    "/",
    trimprefix(google_composer_environment.weather.config[0].dag_gcs_prefix, "gs://"),
  )[0]
}

resource "google_storage_bucket_iam_member" "github_actions_composer_dag_deployer" {
  bucket = local.composer_dag_bucket_name
  role   = google_project_iam_custom_role.github_actions_composer_dag_deployer.name
  member = "serviceAccount:${google_service_account.github_actions_composer_dag_deployer.email}"
}

resource "google_service_account_iam_member" "github_actions_composer_dag_deployer_wif" {
  service_account_id = google_service_account.github_actions_composer_dag_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${data.google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
