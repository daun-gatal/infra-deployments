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
  minio = jsondecode(file(var.minio_credentials_path))
}

module "airflow" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/airflow?ref=main"
  
  
  image_repository = "registry.gitlab.com/daun-gatal/image-repo/airflow"
  
  # Executor configuration
  airflow_executor = "CeleryExecutor"
  
  # Connect to PostgreSQL for metadata
  airflow_metadata_db_conn = "postgresql://${local.db.postgres_username.value}:${local.db.postgres_password.value}@${local.db.postgres_rw_dns.value}:5432/airflow"
  
  # Required secrets
  airflow_fernet_key       = var.airflow_fernet_key
  airflow_api_secret_key   = var.airflow_api_secret_key
  airflow_default_password = var.airflow_password
  
  # Git DAGs configuration with PAT authentication
  git_auth_method              = "pat"
  git_username                 = var.git_username
  git_password                 = var.git_password
  airflow_dags_git_sync_repo   = "https://gitlab.com/daun-gatal/airflow-dags.git"
  airflow_dags_git_sync_branch = "main"
  
  # Connect to MinIO for remote logging
  enable_remote_logging    = true
  airflow_logs_bucket_name = "airflow"
  aws_access_key_id        = local.minio.minio_root_user.value
  aws_secret_access_key    = local.minio.minio_root_password.value
  aws_endpoint_url         = "http://${local.minio.minio_service_dns.value}:${local.minio.minio_service_port.value}"

  airflow_flower_enabled = true
  airflow_worker_keda_enabled = true
  airflow_worker_keda_min_replicas = 1

  tailscale_expose = true
}

# Add comments here if needed v2