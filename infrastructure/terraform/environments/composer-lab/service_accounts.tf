resource "google_service_account" "airflow_orchestrator" {
  project      = var.project_id
  account_id   = "airflow-orchestrator"
  display_name = "Airflow Orchestrator (Cloud Composer)"
}

data "google_service_account" "dataform_runner" {
  project    = var.project_id
  account_id = var.dataform_runner_account_id
}

resource "google_service_account" "github_actions_composer_dag_deployer" {
  project      = var.project_id
  account_id   = "composer-dag-deployer"
  display_name = "GitHub Actions Composer DAG Deployer"
}

data "google_iam_workload_identity_pool" "github" {
  provider = google-beta

  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
}
