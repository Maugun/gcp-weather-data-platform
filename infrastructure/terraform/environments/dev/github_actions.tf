locals {
  github_actions_plan_roles = toset([
    "roles/browser",
    "roles/iam.securityReviewer",
    "roles/iam.serviceAccountViewer",
    "roles/iam.workloadIdentityPoolViewer",
    "roles/run.viewer",
    "roles/artifactregistry.reader",
    "roles/dataform.viewer",
    "roles/bigquery.metadataViewer",
  ])
}

resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions"
  display_name = "GitHub Actions"
}

resource "google_iam_workload_identity_pool" "github" {
  project = var.project_id

  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project = var.project_id

  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"

  display_name = "GitHub"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions.name

  role = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_project_iam_member" "github_actions_plan" {
  for_each = local.github_actions_plan_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_artifact_registry_repository_iam_member" "github_actions_writer" {
  project    = google_artifact_registry_repository.docker.project
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}