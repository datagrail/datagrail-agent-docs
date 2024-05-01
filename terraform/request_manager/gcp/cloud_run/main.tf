terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84, < 6"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.84, < 6"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "datagrail-rm-agent-service-account" {
  account_id   = var.name
  project      = var.project_id
  display_name = "DataGrail Request Manager Agent"
}

resource "google_project_iam_member" "storage-object-creator" {
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.datagrail-rm-agent-service-account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "secret-manager-accessor" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.datagrail-rm-agent-service-account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "artifact-registry-service-agent" {
  role    = "roles/artifactregistry.serviceAgent"
  member  = "serviceAccount:${google_service_account.datagrail-rm-agent-service-account.email}"
  project = var.project_id
}

module "lb-http" {
  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
  version = "~> 10.0"

  name    = "${var.name}-lb"
  project = var.project_id

  ssl                             = var.ssl
  managed_ssl_certificate_domains = [var.domain]
  https_redirect                  = var.ssl

  backends = {
    default = {
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn = false

      iap_config = {
        enable = false
      }
      log_config = {
        enable = false
      }
    }
  }
}

resource "google_cloud_run_v2_service" "datagrail-rm-agent" {
  name     = "${var.name}-service"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.datagrail-rm-agent-service-account.email

    containers {
      name  = var.name
      image = var.agent_image

      ports {
        container_port = 80
      }
      command = ["supervisord", "-n", "-c", "/etc/rm.conf"]

      startup_probe {
        initial_delay_seconds = 1
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
        http_get {
          port = 80
          path = "/docs"
        }
      }

      env {
        name  = "DATAGRAIL_AGENT_CONFIG"
        value = file("../rm-agent-config.json")
      }

      resources {
        limits = {
          cpu    = "2.0"
          memory = "2048Mi"
        }
      }
    }
    annotations = {
      "autoscaling.knative.dev/maxScale"    = "1",
      "autoscaling.knative.dev/minScale"    = "1",
      "autoscaling.knative.dev/client-name" = "terraform",
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.datagrail-rm-agent.name
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_v2_service.datagrail-rm-agent.location
  project  = google_cloud_run_v2_service.datagrail-rm-agent.project
  service  = google_cloud_run_v2_service.datagrail-rm-agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}