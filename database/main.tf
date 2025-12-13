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


module "postgres_db" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/postgres?ref=main"

  db_name      = "default"
  db_user      = "admin"
  db_password  = var.db_password
  storage_size = "30Gi"
  extra_db_names = ["airflow", "metabase", "datalake", "openwebui", "openbaodb", "superset"]
}

output "postgres_rw_dns" {
  description = "Name of the Postgres service"
  value       = module.postgres_db.postgres_rw_dns
}

output "postgres_password" {
  description = "Password for the Postgres"
  value       = module.postgres_db.postgres_password
  sensitive   = true
}

output "postgres_username" {
  description = "Username for the Postgres"
  value       = module.postgres_db.postgres_username
  sensitive   = true
}

# add comments v10