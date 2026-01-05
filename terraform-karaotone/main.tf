# Terraform Settings
terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~>6.0"
        }
    }
}

# Provider Configuration
provider "google" {
    project = "karaotone-prod"
    region = "us-central1"
}

# Enable Required Resources
resource "google_project_service" "enabled_apis" {
    for_each = toset([
        "cloudbuild.googleapis.com",
        "run.googleapis.com",
        "artifactregistry.googleapis.com"
    ])
    service             = each.key
    disable_on_destroy  = false
}

# Artifact Registry
resource "google_artifact_registry_repository" "karaotone_docker_repo" {
    location        = "us-central1"
    repository_id   = "karaotone-images"
    description     = "Repository for Karaotone app Docker images"
    format          = "DOCKER"

    depends_on = [google_project_service.enabled_apis]
}

# Cloud Storage Bucket
resource "google_storage_bucket" "audio_upload" {
    name                        = "karaotone-prod-media-audio-upload"
    location                    = "us-central1"
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    force_destroy               = false
    lifecycle_rule {
        action {
            type = "Delete"
        }
        condition {
            age = 3
        }
    }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "audio_processed" {
    name                        = "karaotone-prod-media-audio-processed"
    location                    = "us-central1"
    storage_class               = "STANDARD"
    uniform_bucket_level_access = true
    force_destroy               = false
    lifecycle_rule {
        action {
            type = "Delete"
        }
        condition {
            age = 3
        }
    }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "webapp" {
    name        = "karaotone-webapp"
    location    = "us-central1"
    scaling {
          manual_instance_count = 0
          min_instance_count    = 0
        }
    template {
        scaling {
            min_instance_count  = 0
        }
        containers {
            # this points to the image available in artifact registry
            image = "us-central1-docker.pkg.dev/${var.project_id}/karaotone-images/karaotone-web:v0.0.2"
            ports {
                container_port = 8080
            }
        }
    }
}

# Make the webapp publically accessible
resource "google_cloud_run_v2_service_iam_member" "webapp_public_access" {
    name        = google_cloud_run_v2_service.webapp.name
    location    = google_cloud_run_v2_service.webapp.location
    role        = "roles/run.invoker"
    member      = "allUsers"
}

# Make the audio buckets publically accessible
resource "google_storage_bucket_iam_member" "audio_upload_public_access" {
    bucket  = google_storage_bucket.audio_upload.name
    role    = "roles/storage.objectViewer"
    member  = "allUsers"
}