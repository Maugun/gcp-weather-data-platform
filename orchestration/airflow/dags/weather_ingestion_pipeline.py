from datetime import timedelta

import pendulum
from airflow.providers.google.cloud.operators.cloud_run import (
    CloudRunExecuteJobOperator,
)
from airflow.providers.google.cloud.operators.dataform import (
    DataformCreateCompilationResultOperator,
    DataformCreateWorkflowInvocationOperator,
)
from airflow.providers.google.cloud.sensors.gcs import (
    GCSObjectUpdateSensor,
)
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import (
    GCSToBigQueryOperator,
)
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT_ID = "de-gcp-lab"
DATAFORM_REGION = "europe-west9"
DATAFORM_REPOSITORY_ID = "weather-dataform"
DATAFORM_WORKSPACE_ID = "dev"
DATAFORM_SERVICE_ACCOUNT = "dataform-runner@de-gcp-lab.iam.gserviceaccount.com"


def current_run_start(context):
    return context["dag_run"].start_date


with DAG(
    dag_id="weather_ingestion_pipeline",
    description="Workflow d'ingestion du weather",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 10, 1, tz="UTC"),
    catchup=False,
    tags=["gcp", "weather", "ingestion"],
    default_args={
        "retries": 2,
        "retry_delay": timedelta(seconds=10),
    },
) as dag:
    show_interval = BashOperator(
        task_id="show_interval",
        bash_command="""
            echo "Logical date : {{ logical_date }}"
            echo "Start        : {{ data_interval_start }}"
            echo "End          : {{ data_interval_end }}"
        """,
    )

    extract = CloudRunExecuteJobOperator(
        task_id="extract_open_meteo",
        project_id="de-gcp-lab",
        region="europe-west1",
        job_name="open-meteo-ingestion",
        gcp_conn_id="google_cloud_default",
        overrides={
            "container_overrides": [
                {
                    "env": [
                        {
                            "name": "TARGET_DATE",
                            "value": "{{ data_interval_start | ds }}",
                        }
                    ]
                }
            ]
        },
        deferrable=False,
    )

    wait_for_gcs_file = GCSObjectUpdateSensor(
        task_id="wait_for_gcs_file",
        bucket="de-gcp-lab-raw",
        object="open_meteo/dt={{ data_interval_start | ds }}/weather.jsonl",
        ts_func=current_run_start,
        google_cloud_conn_id="google_cloud_default",
        poke_interval=10,
        timeout=120,
        deferrable=False,
    )

    load_weather_to_bigquery = GCSToBigQueryOperator(
        task_id="load_weather_to_bigquery",
        bucket="de-gcp-lab-raw",
        source_objects=[
            "open_meteo/dt={{ data_interval_start | ds }}/weather.jsonl",
        ],
        destination_project_dataset_table="de-gcp-lab.weather_raw.open_meteo",
        source_format="NEWLINE_DELIMITED_JSON",
        schema_fields=[
            {"name": "date", "type": "DATE", "mode": "NULLABLE"},
            {"name": "location_name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "latitude", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "longitude", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "timezone", "type": "STRING", "mode": "NULLABLE"},
            {"name": "temperature_2m_max", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "temperature_2m_min", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "temperature_2m_mean", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "precipitation_sum", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "rain_sum", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "wind_speed_10m_max", "type": "FLOAT", "mode": "NULLABLE"},
            {"name": "weather_code", "type": "INTEGER", "mode": "NULLABLE"},
            {"name": "_ingested_at", "type": "TIMESTAMP", "mode": "NULLABLE"},
            {"name": "_source", "type": "STRING", "mode": "NULLABLE"},
            {"name": "_run_id", "type": "STRING", "mode": "NULLABLE"},
        ],
        write_disposition="WRITE_APPEND",
        create_disposition="CREATE_IF_NEEDED",
        gcp_conn_id="google_cloud_default",
        location="EU",
    )

    compile_dataform = DataformCreateCompilationResultOperator(
        task_id="compile_dataform",
        project_id=PROJECT_ID,
        region=DATAFORM_REGION,
        repository_id=DATAFORM_REPOSITORY_ID,
        compilation_result={
            "workspace": (
                f"projects/{PROJECT_ID}"
                f"/locations/{DATAFORM_REGION}"
                f"/repositories/{DATAFORM_REPOSITORY_ID}"
                f"/workspaces/{DATAFORM_WORKSPACE_ID}"
            ),
            "code_compilation_config": {
                "vars": {
                    "target_date": "{{ data_interval_start | ds }}",
                }
            },
        },
        gcp_conn_id="google_cloud_default",
    )

    run_dataform = DataformCreateWorkflowInvocationOperator(
        task_id="run_dataform",
        project_id=PROJECT_ID,
        region=DATAFORM_REGION,
        repository_id=DATAFORM_REPOSITORY_ID,
        workflow_invocation={
            "compilation_result": ("{{ task_instance.xcom_pull('compile_dataform')['name'] }}"),
            "invocation_config": {
                "included_tags": ["weather"],
                "transitive_dependencies_included": True,
                "service_account": DATAFORM_SERVICE_ACCOUNT,
            },
        },
        gcp_conn_id="google_cloud_default",
    )

    show_interval >> extract
    extract >> wait_for_gcs_file
    wait_for_gcs_file >> load_weather_to_bigquery
    load_weather_to_bigquery >> compile_dataform
    compile_dataform >> run_dataform
