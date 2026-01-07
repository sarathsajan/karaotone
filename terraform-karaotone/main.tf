# Terraform Settings
terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = "~>6.0"
        }
    }
}

# Provider Configuration
provider "google" {
    project = "karaotone-prod"
    region  = "us-central1"
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

    depends_on      = [google_project_service.enabled_apis]
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
            type    = "Delete"
        }
        condition {
            age     = 3
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
            type    = "Delete"
        }
        condition {
            age     = 3
        }
    }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "webapp" {
    name                        = "karaotone-webapp"
    location                    = "us-central1"
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
            image               = "us-central1-docker.pkg.dev/${var.project_id}/karaotone-images/karaotone-web:v0.0.5"
            ports {
                container_port  = 8080
            }
        }
    }
}

# add terraform block for the cloud run service for message broker
# dont go for cloud run function as it does not accept pre-build docker images as source
# resource "google_cloud_run_v2_service" "message_broker" {
# }


# Pub/Sub topic
resource "google_pubsub_topic" "file_upload_topic" {
    name                        = "audio-processing-requests-topic"
    message_retention_duration  = "600s"
}

# # Pub/Sub subscription
# uncomment this block to create a push subscription to the message broker cloud run service
# resource "google_pubsub_subscription" "file_process_subscription" {
#     name    = "audio-processing-requests-subscription-message-broker"
#     topic   = "projects/karaotone-prod/topics/audio-processing-requests-topic"
#     push_config {
#         push_endpoint = "https://message-broker-969751202948.europe-west1.run.app"
#     }
#     oidc_token {
#       service_account_email = "969751202948-compute@developer.gserviceaccount.com"
#     }
#     ack_deadline_seconds = 60
#     message_retention_duration = "7200s"  # 2 hours = 2 × 3600 seconds
#     retain_acked_messages = false
#     retry_policy {
#         minimum_backoff = "10s"
#         maximum_backoff = "600s"
#     }
#     expiration_policy {
#         ttl = "2678400s"  # 31 days = 31 × 86400 seconds
#     }
# }

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