# 1. Terraform Settings
terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~>6.0"
        }
    }
}

# 2. Provider Configuration
provider "google" {
    project = "karaotone-prod"
    region = "us-central1"
}

# 3. Enable Required Resources
resource "google_project_service" "enabled_apis" {
    for_each = toset([
        "cloudbuild.googleapis.com",
        "run.googleapis.com",
        "artifactregistry.googleapis.com"
    ])
    service             = each.key
    disable_on_destroy  = false
}

# 4. Artifact Registry
resource "google_artifact_registry_repository" "karaotone_docker_repo" {
    location        = "us-central1"
    repository_id   = "karaotone-images"
    description     = "Repository for Karaotone app Docker images"
    format          = "DOCKER"

    depends_on = [google_project_service.enabled_apis]
}

# 5. Cloud Storage Bucket
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

# 6. Cloud Storage Bucket
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