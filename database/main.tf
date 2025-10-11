terraform {
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


module "postgres_db" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/postgres?ref=update-airflow"

  db_name      = "default"
  db_user      = "admin"
  db_password  = var.db_password
  storage_size = "5Gi"
  # extra_db_names = ["airflow", "metabase", "nessie", "gravitino"]
  # enable_resource_allocation = true
}