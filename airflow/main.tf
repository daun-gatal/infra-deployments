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

locals {
  github_oauth_config = templatefile(
    "${path.module}/templates/github_oauth.tpl",
    {}
  )
}

module "airflow" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/airflow?ref=main"
  
  
  image_repository = "registry.gitlab.com/daun-gatal/image-repo/airflow"
  image_tag = "3.1.1"
  namespace = "airflow"
  
  # Executor configuration
  airflow_executor = "CeleryExecutor"
  enable_log_groomer_sidecar = true
  airflow_log_retention_days = 3
  
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

  tailscale_expose = false

  airflow_enable_triggerer = true
  airflow_triggerer_replicas = 1

  airflow_api_server_config = local.github_oauth_config

  values = {
    securityContexts = {
      pod = {
        runAsUser = 50000
        fsGroup = 50000
        runAsGroup = 50000
      }
    }

    extraEnvFrom = <<-EOT
      - secretRef:
          name: airflow-extraenv-secret
    EOT

    workers = {
      persistence = {
        enabled = true
        size = "10Gi"
        storageClassName = "standard"
        fixPermissions = false
      }
    }

    triggerer = {
      persistence = {
        enabled = true
        size = "10Gi"
        storageClassName = "standard"
        fixPermissions = false
      }
    }

    logs = {
      persistence = {
        enabled = false
        size = "10Gi"
        storageClassName = "standard"
      }
    }

    ingress = {
      apiServer = {
        enabled = true
        path = "/"
        pathType = "Prefix"
        ingressClassName = "tailscale"
        hosts = [
          {
            name = "airflow-web-ext"
            tls = {
              enabled = true
            }
          }
        ]
        annotations = {
          "tailscale.com/funnel": "true"
        }
      }
    }
  }
}

# Add comments here if needed v9