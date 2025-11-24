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
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

module "openbao" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/openbao?ref=main"

  tailscale_expose    = true
}

output "openbao_service_dns" {
  value       = module.openbao.openbao_server_dns
  description = "The Openbao API service DNS name"
}

# add comments v2