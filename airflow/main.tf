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

module "airflow" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/airflow?ref=main"
  
  
  image_repository = "registry.gitlab.com/daun-gatal/image-repo/airflow"
  image_tag = "3.1.4"
  
  # Executor configuration
  airflow_executor = "CeleryExecutor"
  
  # Connect to PostgreSQL for metadata
  airflow_metadata_db_conn = "postgresql://${var.db_user}:${var.db_password}@${var.db_internal_dns}:5432/airflow"
  
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
  aws_access_key_id        = var.minio_root_user
  aws_secret_access_key    = var.minio_root_password
  aws_endpoint_url         = "http://${var.minio_internal_dns}:9000"

  airflow_flower_enabled = true
  airflow_worker_keda_enabled = true
  airflow_worker_keda_min_replicas = 1
  airflow_worker_keda_max_replicas = 2

  tailscale_expose = true
}

# Add comments here if needed v5