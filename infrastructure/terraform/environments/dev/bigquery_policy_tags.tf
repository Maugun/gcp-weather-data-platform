resource "google_data_catalog_taxonomy" "weather_data_classification" {
  project      = var.project_id
  region       = lower(var.data_location)
  display_name = "Weather Data Classification"
  description  = "Classification taxonomy for sensitive fields in the weather analytics platform."

  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

  depends_on = [google_project_service.data_catalog]
}

resource "google_data_catalog_policy_tag" "operator_email" {
  taxonomy     = google_data_catalog_taxonomy.weather_data_classification.name
  display_name = "Operator Contact"
  description  = "Personally identifiable contact information for a weather station operator."
}

resource "google_project_iam_custom_role" "dataform_taxonomy_reader" {
  project     = var.project_id
  role_id     = "dataformTaxonomyReader"
  title       = "Dataform Taxonomy Reader"
  description = "Read the policy-tag taxonomy so Dataform can apply its tags to curated columns."
  permissions = ["datacatalog.taxonomies.get"]
}

resource "google_data_catalog_taxonomy_iam_member" "dataform_runner_taxonomy_reader" {
  taxonomy = google_data_catalog_taxonomy.weather_data_classification.name
  role     = google_project_iam_custom_role.dataform_taxonomy_reader.name
  member   = "serviceAccount:${google_service_account.workloads["dataform-runner"].email}"
}

resource "google_data_catalog_policy_tag_iam_member" "weather_fr_analyst_operator_contact_reader" {
  policy_tag = google_data_catalog_policy_tag.operator_email.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = "serviceAccount:${google_service_account.workloads["weather-fr-analyst"].email}"
}
