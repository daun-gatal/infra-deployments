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


module "airbyte" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/airbyte?ref=main"
}

# Add comments here if needed v1