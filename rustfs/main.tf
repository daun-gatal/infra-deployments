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

module "rustfs" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/rustfs?ref=main"

  tailscale_expose = true
  deployment_type = "statefulset"
  replica_count = 4

  values = {
    consoleService = {
      enabled = true
    }

    dataPersistence = {
      enabled = true
      storageClass = "standard"
      size = "12Gi"
    }

    logsPersistence = {
      enabled = false
      storageClass = "standard"
      size = "5Gi"
    }
  }

  resources = {
    limits = {
      cpu    = "1"
      memory = "4Gi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}