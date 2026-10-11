# GCP Weather Data Platform

A production-oriented data engineering project built on Google Cloud Platform.

The platform ingests weather data from the Open-Meteo API, stores raw data in Google Cloud Storage and BigQuery, transforms it with Dataform, and orchestrates the pipeline with Apache Airflow.

The project is progressively extended with additional ingestion patterns, Infrastructure as Code, security practices and CI/CD workflows.

## Architecture

```mermaid
flowchart LR
    API[Open-Meteo API] --> CR[Cloud Run Job]
    CR --> GCS[GCS RAW]
    GCS --> BQRAW[BigQuery RAW]

    BQRAW --> DF[Dataform]
    DF --> STG[BigQuery STAGING]
    STG --> CUR[BigQuery CURATED]

    AF[Apache Airflow] --> CR
    AF --> BQRAW
    AF --> DF

    GH[GitHub Actions] --> WIF[Workload Identity Federation]
    WIF --> GHA[github-actions Service Account]

    GHA --> AR[Artifact Registry]
    GHA --> TF[Terraform]
    TF --> GCP[GCP Infrastructure]

    AR --> CR
```

## Tech Stack

- Google Cloud Platform
- BigQuery
- Google Cloud Storage
- Cloud Run Jobs
- Artifact Registry
- Dataform
- Apache Airflow
- Terraform
- GitHub Actions
- Workload Identity Federation
- Python
- Docker
- Ruff

## Repository Structure

```text
.
├── infrastructure/
│   └── terraform/
│       └── environments/
│           └── dev/
│               ├── backend.tf
│               ├── versions.tf
│               ├── providers.tf
│               ├── variables.tf
│               ├── main.tf
│               ├── service_accounts.tf
│               ├── iam.tf
│               ├── services.tf
│               ├── cloud_run.tf
│               ├── dataform.tf
│               ├── artifact_registry.tf
│               ├── github_actions.tf
│               ├── outputs.tf
│               ├── terraform.tfvars.example
│               └── .terraform.lock.hcl
│
├── ingestion/
│   └── open-meteo/
│       ├── main.py
│       ├── requirements.txt
│       ├── Dockerfile
│       └── .dockerignore
│
├── orchestration/
│   └── airflow/
│       ├── dags/
│       │   └── weather_ingestion_pipeline.py
│       └── docker-compose.yaml
│
├── transformation/
│   └── dataform/
│       ├── workflow_settings.yaml
│       └── definitions/
│
├── docs/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── build-open-meteo.yml
│
├── pyproject.toml
├── .gitignore
└── README.md
```

## Current Pipeline

The Open-Meteo ingestion pipeline follows:

```text
Open-Meteo API
    ↓
Cloud Run Job
    ↓
Google Cloud Storage - RAW
    ↓
BigQuery - RAW
    ↓
Dataform
    ↓
BigQuery - STAGING
    ↓
BigQuery - CURATED
```

Apache Airflow orchestrates the pipeline and uses its logical data interval to make ingestion and transformations deterministic and replayable.

For each scheduled run, Airflow:

1. Executes the Open-Meteo Cloud Run Job.
2. Waits for the expected GCS object to be refreshed.
3. Loads the raw NDJSON file into BigQuery.
4. Compiles Dataform with the target processing date.
5. Executes the Dataform workflow.
6. Produces a deduplicated incremental staging dataset.

## Data Layers

The project follows a layered data architecture.

### RAW

Raw data is kept close to the source and can contain multiple ingestion versions for the same logical record.

The goal of the RAW layer is to preserve source data and make ingestion replayable.

### STAGING

Data is cleaned, typed and deduplicated.

For the Open-Meteo pipeline, the logical grain is:

```text
(date, location_name)
```

Dataform incremental models use a `uniqueKey` and `MERGE` strategy to keep the latest ingestion for each logical record.

The latest record is determined using ingestion metadata such as:

```text
_ingested_at
_run_id
```

### CURATED

The curated layer contains data prepared for downstream analytics and business use cases.

It is separated from STAGING so that technical transformations and business-facing models can evolve independently.

## Open-Meteo Ingestion

The Open-Meteo ingestion component is implemented in Python and executed as a Cloud Run Job.

It:

- calls the Open-Meteo API
- supports a target processing date
- retries transient HTTP failures
- generates NDJSON
- writes raw data to GCS
- emits structured logs
- runs using a dedicated Service Account

The ingestion code lives in:

```text
ingestion/open-meteo/
```

The application is packaged as a Docker image:

```text
Python application
    ↓
Docker image
    ↓
Artifact Registry
    ↓
Cloud Run Job
```

Docker images are versioned using Git commit SHAs to provide traceability between source code and application artifacts.

Example:

```text
open-meteo:a84dc312f68e...
```

instead of relying on mutable tags such as:

```text
latest
```

## Airflow Orchestration

Apache Airflow is currently run locally using Docker Compose.

The DAG is versioned in Git:

```text
orchestration/airflow/dags/weather_ingestion_pipeline.py
```

Airflow coordinates the execution of external services rather than performing data processing itself.

The DAG currently orchestrates:

```text
Cloud Run ingestion
    ↓
GCS object availability
    ↓
BigQuery RAW load
    ↓
Dataform compilation
    ↓
Dataform workflow execution
```

A freshness-aware GCS sensor ensures that Airflow waits for an object updated during the current DAG run rather than accepting a stale object already present in the bucket.

A future production deployment can use Google Cloud Composer.

## Dataform

Dataform manages SQL transformations between BigQuery data layers.

The Dataform project contains:

```text
transformation/dataform/
├── workflow_settings.yaml
└── definitions/
```

Transformations are versioned as code and executed programmatically by Airflow using the Dataform API.

The STAGING model uses:

- incremental processing
- `uniqueKey`
- BigQuery `MERGE`
- partitioning
- clustering
- assertions
- source deduplication
- processing-date variables

This makes transformations deterministic and safe to replay.

## Infrastructure as Code

Terraform manages the GCP infrastructure.

Currently managed resources include:

- BigQuery datasets
- Service Accounts
- IAM permissions
- Cloud Run Job
- Artifact Registry
- Dataform repository
- GitHub Workload Identity Federation
- required GCP service configuration

Existing resources originally created manually are progressively imported into Terraform before Terraform becomes their source of truth.

The migration strategy is:

```text
ClickOps
    ↓
Understand and validate the resource
    ↓
Import into Terraform
    ↓
Terraform becomes source of truth
```

The Terraform state is stored remotely in Google Cloud Storage.

```text
Git
→ Terraform configuration

GCS
→ Terraform state

GCP
→ Real infrastructure
```

Infrastructure changes follow:

```text
terraform fmt
    ↓
terraform validate
    ↓
terraform plan
    ↓
review
    ↓
terraform apply
```

Environment-specific configuration is separated from reusable Terraform code.

```text
variables.tf
→ declares expected configuration

terraform.tfvars.example
→ documents example values

terraform.tfvars
→ local environment configuration
→ not committed
```

Deployment-time values are not stored as permanent repository configuration.

The Open-Meteo Docker image version is supplied through:

```text
TF_VAR_open_meteo_image_tag
```

After a deployment, Terraform persists the deployed value in its remote state.

The version currently managed by Terraform can therefore be retrieved with:

```bash
terraform output -raw open_meteo_image_tag
```

## Application Versioning

Stable environment configuration and application release state are intentionally separated.

GitHub repository variables contain environment configuration:

```text
GCP_PROJECT_ID
GCP_REGION
GCP_WIF_PROVIDER
GCP_SERVICE_ACCOUNT
```

The candidate application version is derived directly from Git:

```text
Git commit
    ↓
github.sha
    ↓
Docker image tag
```

The version currently managed by Terraform is persisted in the remote Terraform state:

```text
Terraform state
    ↓
open_meteo_image_tag
    ↓
currently deployed image
```

This avoids maintaining a mutable application version manually in GitHub repository variables.

## Security

The project follows least-privilege IAM principles.

Key practices include:

- dedicated Service Accounts per workload
- project-level permissions only when required
- resource-level IAM when possible
- dataset-level BigQuery permissions
- Service Account impersonation
- Secret Manager for sensitive values
- Application Default Credentials for local development
- GitHub OIDC authentication
- Workload Identity Federation
- no long-lived Service Account JSON keys in GitHub
- separate runtime and CI/CD identities

### Dataform Runtime Identity

The Dataform runtime identity has:

```text
Project
└── BigQuery Job User

weather_raw
└── BigQuery Data Viewer

weather_staging
└── BigQuery Data Editor

dataform_assertions
└── BigQuery Data Editor
```

The Dataform Service Agent is allowed to impersonate the dedicated:

```text
dataform-runner
```

Service Account.

### Open-Meteo Runtime Identity

The Cloud Run ingestion workload uses its own identity:

```text
open-meteo-ingestion
```

Application runtime permissions are therefore kept separate from CI/CD permissions.

### GitHub Actions Identity

GitHub Actions uses a dedicated identity:

```text
github-actions
```

This prevents CI/CD, ingestion and transformation workloads from sharing the same identity.

For application build and deployment, the GitHub Actions identity has narrowly scoped permissions:

```text
Artifact Registry repository
└── Artifact Registry Writer

open-meteo-ingestion Cloud Run Job
└── Cloud Run Developer

open-meteo-ingestion Service Account
└── Service Account User
```

This allows GitHub Actions to:

```text
push Docker images
    +
update the dedicated Cloud Run Job
    +
attach its runtime Service Account
```

without granting broad project-wide deployment permissions.

## GitHub Authentication

GitHub Actions authenticates to Google Cloud using Workload Identity Federation.

```text
GitHub Actions
    ↓
GitHub OIDC token
    ↓
GCP Workload Identity Provider
    ↓
github-actions Service Account
    ↓
temporary GCP credentials
```

The Workload Identity Provider restricts authentication to the expected GitHub repository.

This avoids storing credentials such as:

```text
service-account-key.json
```

inside GitHub Secrets.

Authentication and authorization remain separate:

```text
Workload Identity Federation
→ Who is calling?

IAM
→ What is that identity allowed to do?
```

## CI/CD

GitHub Actions automates project validation and application delivery.

The pipeline separates three responsibilities:

```text
CI
→ validate code and infrastructure

BUILD
→ create an immutable application artifact

DEPLOY
→ release a selected artifact to Cloud Run
```

## Continuous Integration

The main CI workflow runs on pushes to `master` and on pull requests.

### Python Quality

Python code is validated with Ruff:

```bash
ruff check .
ruff format --check .
```

### Terraform Validation

Terraform configuration is validated with:

```text
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

The workflow authenticates to GCP through Workload Identity Federation and reads the real remote Terraform state.

Before executing `terraform plan`, CI retrieves the Open-Meteo image version currently managed by Terraform:

```text
terraform init
    ↓
terraform output open_meteo_image_tag
    ↓
TF_VAR_open_meteo_image_tag
    ↓
terraform plan
```

This prevents unrelated Git commits from being interpreted as new application releases.

For example:

```text
README change
    ↓
new Git SHA
    ↓
CI runs
    ↓
currently deployed Open-Meteo tag loaded from Terraform state
    ↓
Terraform plans against the real deployed version
```

CI never performs `terraform apply`.

## Open-Meteo Build

The Open-Meteo workflow is scoped to:

```text
ingestion/open-meteo/**
```

This prevents unrelated repository changes from creating unnecessary Docker images.

```text
README change
→ no Open-Meteo build

Terraform change
→ no Open-Meteo build

Airflow change
→ no Open-Meteo build

Open-Meteo change
→ Docker build ✅
```

When triggered, GitHub Actions uses the Git commit SHA as an immutable Docker image tag:

```text
Open-Meteo source change
    ↓
Git commit
    ↓
github.sha
    ↓
Docker build
    ↓
open-meteo:<github.sha>
    ↓
Artifact Registry
```

The workflow can also be triggered manually using:

```text
workflow_dispatch
```

The automated Docker build and Artifact Registry push have been validated successfully.

## Deployment Model

Build and deployment are intentionally treated as separate concepts.

```text
BUILD
Docker image creation
        ↓
Artifact Registry


DEPLOY
Selected immutable image
        ↓
Cloud Run Job
```

The deployment flow is designed as:

```text
Open-Meteo change
    ↓
GitHub SHA
    ↓
Docker build
    ↓
Artifact Registry push
    ↓
TF_VAR_open_meteo_image_tag=<github.sha>
    ↓
Terraform plan
    ↓
Terraform apply
    ↓
Cloud Run Job updated
    ↓
Terraform state updated
    ↓
Cloud Run Job smoke test
```

Terraform plans are saved before being applied:

```text
terraform plan -out=tfplan
        ↓
terraform apply tfplan
```

This ensures that deployment applies exactly the plan generated by the workflow.

After deployment, the Cloud Run Job is executed as a smoke test to verify that the new image can start and successfully execute its workload.

No GitHub variable needs to be manually synchronized with the deployed application version.

## Deployment Protection

Application deployment is associated with the GitHub Environment:

```text
dev
```

This explicitly represents the target environment in GitHub Actions and provides a place for future environment-level protection rules.

Only the `master` branch is allowed to execute the deployment job.

The automatic trigger already restricts application deployments to:

```yaml
push:
  branches:
    - master
```

The deployment job also contains an additional guard:

```yaml
if: github.ref == 'refs/heads/master'
```

This protects manual `workflow_dispatch` executions as well.

As a result:

```text
master
→ deployment allowed

feature/*
→ deployment skipped
```

### Deployment Concurrency

Deployments are serialized using a GitHub Actions concurrency group:

```yaml
concurrency:
  group: open-meteo-dev-deploy
  cancel-in-progress: false
```

This prevents two deployments from attempting to modify the same Cloud Run Job and Terraform state concurrently.

```text
Deployment A
        ↓
Terraform apply
        ↓
complete

Deployment B
        ↓
waits
        ↓
starts after A
```

Running deployments are not cancelled when a newer commit arrives.

This complements Terraform state locking and avoids interrupting an infrastructure operation while it is in progress.

## CI/CD Flow

The complete separation is:

```text
Pull Request / Push
        ↓
       CI
        ↓
Ruff
Terraform validation
Terraform plan
        ↓
No infrastructure mutation
```

For application changes merged to `master`:

```text
ingestion/open-meteo/** changed
        ↓
Build and Deploy Open-Meteo
        ↓
GitHub Environment: dev
        ↓
Docker build
        ↓
Artifact Registry push
        ↓
Terraform plan
        ↓
Terraform apply
        ↓
Cloud Run Job
        ↓
Smoke test
```

Unrelated repository changes do not produce application releases:

```text
README change
→ CI only

Terraform change
→ CI only

Airflow change
→ CI only

Open-Meteo change on master
→ CI + application build/deployment
```

## Idempotency

The pipeline is designed to be safely replayable.

A rerun for the same logical date can create another RAW ingestion version, while the STAGING layer keeps only the latest logical record.

```text
RAW

2026-10-10 / Paris / run A
2026-10-10 / Paris / run B

        ↓ Dataform

STAGING

2026-10-10 / Paris / run B
```

This allows historical runs and failed pipelines to be replayed without producing duplicated business records downstream.

Idempotency is handled at multiple levels:

```text
Ingestion
→ deterministic target date and object path

RAW
→ ingestion history can be preserved

STAGING
→ deduplication + MERGE on logical grain

Orchestration
→ deterministic Airflow data interval
```

## Ingestion Patterns

The platform demonstrates different ingestion strategies depending on the source system.

### REST API

```text
Open-Meteo
→ Python
→ Cloud Run Job
→ GCS
→ BigQuery
```

This demonstrates custom API ingestion when a managed connector is not appropriate.

### AWS S3

```text
AWS S3
→ BigQuery Data Transfer Service
→ BigQuery
```

This demonstrates managed multi-cloud batch ingestion.

### PostgreSQL

```text
PostgreSQL
→ Datastream
→ BigQuery
```

This demonstrates Change Data Capture for transactional databases.

The objective is not to force every source through the same ingestion mechanism, but to select an appropriate ingestion strategy for each source.

## Development

Python formatting and linting are managed globally with Ruff through:

```text
pyproject.toml
```

Runtime dependencies remain specific to each workload.

The Open-Meteo ingestion dependencies are defined in:

```text
ingestion/open-meteo/requirements.txt
```

The local Airflow environment is configured through Docker Compose.

### Python Checks

```bash
ruff check .
ruff format --check .
```

### Terraform Checks

From:

```text
infrastructure/terraform/environments/dev/
```

run:

```bash
terraform fmt
terraform validate
terraform plan
```

For local Terraform operations, deployment-time values can be loaded from a non-committed `.env` file.

Example:

```bash
TF_VAR_open_meteo_image_tag="your-image-tag"
```

With Git Bash:

```bash
set -a
source .env
set +a
```

Local files such as:

```text
.env
terraform.tfvars
```

are not committed.

Example configuration files can be versioned safely:

```text
.env.example
terraform.tfvars.example
```

## Design Principles

The project intentionally applies production-oriented principles:

```text
Infrastructure
→ Infrastructure as Code

Identity
→ one Service Account per responsibility

Permissions
→ least privilege and narrow resource scopes

Authentication
→ short-lived credentials

Application artifacts
→ immutable Git SHA image tags

Configuration
→ stable configuration separated from release state

Data
→ RAW / STAGING / CURATED separation

Processing
→ incremental and idempotent

Orchestration
→ Airflow coordinates external services

Transformations
→ SQL transformations managed by Dataform

Terraform
→ remote state in GCS

CI
→ validation without infrastructure mutation

Build
→ only when application sources change

Deployment
→ master branch only

Environment
→ explicit dev deployment target

Concurrency
→ one application deployment at a time
```

## Roadmap

- [x] Open-Meteo API ingestion
- [x] Cloud Run Job
- [x] GCS RAW storage
- [x] BigQuery RAW ingestion
- [x] Airflow orchestration
- [x] Dataform incremental transformations
- [x] Service Account separation
- [x] Least-privilege IAM
- [x] Terraform foundation
- [x] Remote Terraform state in GCS
- [x] Import existing GCP resources into Terraform
- [x] Cloud Run Job managed by Terraform
- [x] Artifact Registry managed by Terraform
- [x] Dataform repository managed by Terraform
- [x] Dockerized Open-Meteo ingestion
- [x] GitHub Actions CI
- [x] Workload Identity Federation
- [x] Terraform plan using remote state from GitHub Actions
- [x] Automated Docker build
- [x] Artifact Registry push from GitHub Actions
- [x] Scoped CI/CD deployment permissions
- [x] GitHub `dev` deployment environment
- [x] Master-only deployment protection
- [x] Serialized deployment concurrency
- [x] Automated Cloud Run deployment
- [x] Post-deployment Cloud Run smoke test
- [ ] Dataform Git integration
- [ ] AWS S3 ingestion integration
- [ ] PostgreSQL CDC with Datastream integration
- [ ] Monitoring and data quality
- [ ] Production-ready Airflow / Cloud Composer deployment

```

```
