terraform {
  backend "http" {}
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
}

provider "kubernetes" {
  config_path = ""
}

provider "helm" {
  kubernetes = {
    config_path = ""
  }
}

locals {
  github_oauth_config = templatefile(
    "${path.module}/templates/github_oauth.tpl",
    {
      auth_user_registration_role = "Admin"
    }
  )
}


module "superset" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/superset?ref=main"

  superset_secret_key = var.superset_secret_key
  admin_password      = var.admin_password
  use_external_database = true
  database_uri       = "postgresql://${var.db_user}:${var.db_password}@${var.db_internal_dns}:5432/superset"

  enable_celery_worker = true
  enable_celery_beat   = true

  tailscale_expose = true

  bootstrap_pip_packages = ["trino"]

  values = {
    supersetNode = {
        autoscaling = {
            enabled = true
            minReplicas = 1
            maxReplicas = 2
            targetCPUUtilizationPercentage = 90
            targetMemoryUtilizationPercentage = 90
        }
    }
    supersetWorker = {
        autoscaling = {
            enabled = true
            minReplicas = 1
            maxReplicas = 2
            targetCPUUtilizationPercentage = 90
            targetMemoryUtilizationPercentage = 90
        }
    }
    service = {
        port = 80
    }
    envFromSecret = "superset-custom-secret"
    extraEnvRaw = [
        {
            name = "GITHUB_CLIENT_ID"
            value = var.github_client_id
        },
        {
            name = "GITHUB_CLIENT_SECRET"
            value = var.github_client_secret
        }
    ]
  }
}

# Add comments here v1