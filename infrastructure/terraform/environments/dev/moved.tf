# BigQuery dataset IAM grants now use for_each.
moved {
  from = google_bigquery_dataset_iam_member.dataform_raw_viewer
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["dataform_raw_viewer"]
}

moved {
  from = google_bigquery_dataset_iam_member.dataform_staging_editor
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["dataform_staging_editor"]
}

moved {
  from = google_bigquery_dataset_iam_member.dataform_curated_editor
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["dataform_curated_editor"]
}

moved {
  from = google_bigquery_dataset_iam_member.dataform_curated_governance_manager
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["dataform_curated_governance_manager"]
}

moved {
  from = google_bigquery_dataset_iam_member.dataform_assertions_editor
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["dataform_assertions_editor"]
}

moved {
  from = google_bigquery_dataset_iam_member.bigquery_s3_transfer_editor
  to   = google_bigquery_dataset_iam_member.workload_dataset_grants["bigquery_s3_transfer_editor"]
}

# Project-level IAM grants now use for_each.
moved {
  from = google_project_iam_member.dataform_runner_job_user
  to   = google_project_iam_member.workload_project_grants["dataform_runner_job_user"]
}

moved {
  from = google_project_iam_member.weather_fr_analyst_job_user
  to   = google_project_iam_member.workload_project_grants["weather_fr_analyst_job_user"]
}

moved {
  from = google_project_iam_member.weather_api_cloud_sql_client
  to   = google_project_iam_member.workload_project_grants["weather_api_cloud_sql_client"]
}

moved {
  from = google_project_iam_member.bigquery_s3_transfer_job_user
  to   = google_project_iam_member.workload_project_grants["bigquery_s3_transfer_job_user"]
}

# Secret Manager secrets now use for_each.
moved {
  from = google_secret_manager_secret.weather_db_password
  to   = google_secret_manager_secret.secrets["weather_db_password"]
}

moved {
  from = google_secret_manager_secret.datastream_db_password
  to   = google_secret_manager_secret.secrets["datastream_db_password"]
}

moved {
  from = google_secret_manager_secret.aws_s3_secret_access_key
  to   = google_secret_manager_secret.secrets["aws_s3_secret_access_key"]
}

# GitHub Actions service-account grants now use for_each.
moved {
  from = google_service_account_iam_member.github_actions_open_meteo_user
  to   = google_service_account_iam_member.github_actions_workload_users["github_actions_open_meteo_user"]
}

moved {
  from = google_service_account_iam_member.github_actions_weather_api_gateway_user
  to   = google_service_account_iam_member.github_actions_workload_users["github_actions_weather_api_gateway_user"]
}

moved {
  from = google_service_account_iam_member.github_actions_weather_api_user
  to   = google_service_account_iam_member.github_actions_workload_users["github_actions_weather_api_user"]
}

# GitHub Actions Secret Manager grants now use for_each.
moved {
  from = google_secret_manager_secret_iam_member.github_actions_weather_db_viewer
  to   = google_secret_manager_secret_iam_member.github_actions_secrets["github_actions_weather_db_viewer"]
}

moved {
  from = google_secret_manager_secret_iam_member.github_actions_datastream_db_viewer
  to   = google_secret_manager_secret_iam_member.github_actions_secrets["github_actions_datastream_db_viewer"]
}

moved {
  from = google_secret_manager_secret_iam_member.github_actions_aws_s3_secret_viewer
  to   = google_secret_manager_secret_iam_member.github_actions_secrets["github_actions_aws_s3_secret_viewer"]
}

moved {
  from = google_secret_manager_secret_iam_member.github_actions_aws_s3_secret_accessor
  to   = google_secret_manager_secret_iam_member.github_actions_secrets["github_actions_aws_s3_secret_accessor"]
}

# Dataform service-agent grants now use for_each.
moved {
  from = google_service_account_iam_member.dataform_service_agent_user
  to   = google_service_account_iam_member.dataform_runner_grants["dataform_service_agent_user"]
}

moved {
  from = google_service_account_iam_member.dataform_service_agent_token_creator
  to   = google_service_account_iam_member.dataform_runner_grants["dataform_service_agent_token_creator"]
}

# Weather API service IAM grants now share a for_each resource.
moved {
  from = google_cloud_run_v2_service_iam_member.github_actions_weather_api_developer
  to   = google_cloud_run_v2_service_iam_member.weather_api_grants["github_actions_weather_api_developer"]
}

moved {
  from = google_cloud_run_v2_service_iam_member.weather_api_gateway_invoker
  to   = google_cloud_run_v2_service_iam_member.weather_api_grants["weather_api_gateway_invoker"]
}
