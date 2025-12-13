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

  admin_password      = var.admin_password
  oauth_config = local.github_oauth_config
  use_external_database = true

  enable_celery_worker = true
  enable_celery_beat   = true

  tailscale_expose = true
  superset_port = 80

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
  }
}

# Add comments here v2