# DevOps Final Project

This repository contains a Django application and a CI pipeline that validates:

- container build and runtime health
- software bill of materials (SBOM) generation and vulnerability scanning
- Terraform Stage 1 infrastructure provisioning via a custom GitHub Action

## Project Structure

- `manage.py` and `final_app/`: Django application
- `Dockerfile`: application container image definition
- `.github/workflows/build-and-curl.yml`: main GitHub Actions workflow
- `.github/actions/sbom-scan/`: custom Docker-based action for SBOM and CVE scanning
- `.github/actions/terraform/`: custom Docker-based action for Terraform execution
- `stage1/main.tf`: Terraform Stage 1 footprint (provider/backend + ACR)

## Local Development

### Prerequisites

- Python 3.13+ (or compatible environment)
- Docker Desktop / Docker Engine

### Install dependencies

```bash
pip install -r requirements.txt
```

### Run Django locally (non-container)

```bash
export DJANGO_SECRET_KEY="replace-with-your-secret"
python manage.py runserver 0.0.0.0:8000
```

### Build and run with Docker

```bash
docker build -t django-final-app .
docker run --rm -p 8000:8000 -e DJANGO_SECRET_KEY="replace-with-your-secret" django-final-app
```

App URL: `http://localhost:8000`

## CI Workflow Overview

Workflow file: `.github/workflows/build-and-curl.yml`

This workflow is manually triggered with `workflow_dispatch` and contains three jobs:

1. `docker-build-curl-test`
   - Checks out code
   - Builds app image
   - Runs app container
   - Validates endpoint response with `curl`

2. `sbom-scan-test`
   - Runs custom local action at `./.github/actions/sbom-scan`
   - Generates `sbom.json`
   - Scans with `grype` and fails on critical vulnerabilities
   - Uploads SBOM artifact (`project-sbom`)

3. `terraform-stage-test` (optional)
   - Runs only when `run_terraform=true`
   - Depends on successful completion of the first two jobs
   - Runs custom local action at `./.github/actions/terraform`

## Required GitHub Secrets

### Application / container test

- `DJANGO_SECRET_KEY`

### Terraform action credentials

- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`

## Running Terraform Stage 1 in Actions

In the Actions UI, run the `Build and Curl` workflow and set:

- `run_terraform = true`
- `tf_stage = stage1`
- `state_key = dswanberg` (or your assigned unique key)

The Terraform action expects `stage1/main.tf` to exist in the repository root.

## Notes

- The application base image and third-party GitHub Actions are pinned by SHA/digest for reproducibility.
- The Terraform action currently implements Stage 1 behavior only.
