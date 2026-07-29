# Karaotone

A prototype karaoke audio pipeline built with Flask, Google Cloud, and Terraform.

## Project Overview

- `flask-webapp/`: front-end Flask application for uploading audio files and triggering processing.
- `karaoke-generator/`: placeholder audio processing service that currently moves uploaded audio from the upload bucket to a processed bucket.
- `terraform-karaotone/`: Terraform configuration for Google Cloud resources, including Cloud Run, Pub/Sub, Artifact Registry, and Storage buckets.

## Features

- Upload audio files (`.mp3`, `.wav`, `.flac`, `.m4a`) from a web UI.
- Store uploads in a Google Cloud Storage bucket.
- Publish processing requests to a Google Cloud Pub/Sub topic.
- Serve the frontend with Cloud Run.
- Use Terraform to provision infrastructure.

## Repository Structure

- `flask-webapp/`
  - `app_server.py`: Flask application and upload handling.
  - `templates/`: HTML templates for pages and layouts.
  - `static/`: static assets for the web UI.
  - `Dockerfile`: Docker image definition for the web app.
  - `requirements.txt`: Python dependencies for the web app.
- `karaoke-generator/`
  - `app_audioseparator.py`: audio processing service stub.
  - `Dockerfile`: Docker image definition for the processor.
  - `requirements.txt`: Python dependencies for the processor.
- `terraform-karaotone/`
  - `main.tf`: Terraform resources for GCP.
  - `variables.tf`, `terraform.tfvars`: Terraform configuration.

## Local Setup

1. Install Python 3.11 and Docker.
2. Set Google credentials for local testing:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

3. Run the Flask app locally:

```powershell
cd "flask-webapp"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:FLASK_APP="app_server.py"
python -m flask run --host=0.0.0.0 --port=8080
```

4. Open the web UI at `http://127.0.0.1:8080`.

## Docker / Cloud Run

Build and push the web app image:

```powershell
docker build -t gcr.io/<PROJECT_ID>/karaotone-web:v0.0.5 ./flask-webapp
```

Build and push the processor image:

```powershell
docker build -t gcr.io/<PROJECT_ID>/karaotone-audio-separator:v0.0.1 ./karaoke-generator
```

Use Cloud Run or Terraform to deploy these containers.

## Terraform Deployment

1. Configure the GCP project and credentials.
2. From `terraform-karaotone/`:

```powershell
cd "terraform-karaotone"
terraform init
terraform apply
```

3. Review the resources created by Terraform:
  - `google_cloud_run_v2_service.webapp`
  - `google_pubsub_topic.file_upload_topic`
  - `google_storage_bucket.audio_upload`
  - `google_storage_bucket.audio_processed`

## Important Notes

- The project currently hard-codes `PROJECT_ID = "karaotone-prod"` and bucket/topic names in code and Terraform.
- `karaoke-generator/app_audioseparator.py` is a stub and uses `gcloud storage mv` to move files; it should be updated to implement real audio separation and processing logic.
- Cloud Run services may require proper service account permissions for Storage and Pub/Sub.
- The `audio_processed` page assumes a processed file name format of `processed_<original_name>.mp3`.

## Next Steps

- Implement actual audio separation and karaoke vocal extraction.
- Add Pub/Sub subscription or Cloud Run message broker to trigger processing automatically.
- Secure credentials and remove hard-coded production values.
- Add tests and error handling for production usage.
