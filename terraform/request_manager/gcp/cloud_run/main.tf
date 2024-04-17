terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  project = "pivotal-shield-419918"
  region  = "us-west1"
}

resource "google_cloud_run_service" "default" {
  name     = "datagrail-rm-agent-srv"
  location = "us-west1"

  template {
    spec {
      containers {
        name  = "datagrail-rm-agent"
        image = "us-docker.pkg.dev/pivotal-shield-419918/datagrail-rm-agent/datagrail-rm-agent:latest"

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
          value = file("config/rm-agent-config.json")
        }

        resources {
          limits = {
            cpu    = "2.0"
            memory = "2048Mi"
          }
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"    = "1",
        "autoscaling.knative.dev/minScale"    = "1",
        "autoscaling.knative.dev/client-name" = "terraform",
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
