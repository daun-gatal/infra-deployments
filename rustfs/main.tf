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

module "minio" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/rustfs?ref=main"

  service_annotations = {
    "tailscale.com/expose" = "true"
    "tailscale.com/hostname" = "rustfs-int"
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