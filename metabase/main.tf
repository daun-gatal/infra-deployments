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

locals {
  db = jsondecode(file(var.db_credentials_path))
}

module "metabase" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/metabase?ref=main"

  metabase_db_password = local.db.postgres_password.value
  metabase_db_user     = local.db.postgres_username.value
  metabase_db_host     = local.db.postgres_rw_dns.value
  metabase_db_port     = 5432
  metabase_db_name     = "metabase"
  tailscale_expose     = true
  tailscale_funnel    = true
}

# Add comments here v4