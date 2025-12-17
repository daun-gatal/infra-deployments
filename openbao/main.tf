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

module "openbao" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/openbao?ref=main"

  tailscale_ui_expose    = true

  server_storage_secret_name = "openbao-storage-config-v1"
  server_unseal_secret_name = "openbao-unseal-key-v1"
  unseal_previous_key = "RHz3ki3SPdNYt29OATyK7JqhWMvHBI0+ML571cbe4dA="
  unseal_previous_key_id = "12345-1"
  unseal_current_key_id = "20251217-1"
  
  storage_type = "postgresql"
  storage_postgresql = {
    connection_url = "postgres://${var.db_user}:${var.db_password}@${var.db_internal_dns}:5432/openbaodb?sslmode=disable"
    ha_enabled     = true
    max_connect_retries = 5
    skip_create_table = true
  }
}

output "openbao_service_dns" {
  value       = module.openbao.openbao_server_dns
  description = "The Openbao API service DNS name"
}

# add comments v4