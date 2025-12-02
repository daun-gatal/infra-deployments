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
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/minio?ref=main"

  minio_root_password = var.minio_root_password
  tailscale_expose    = true
  storage_size       = "50Gi"

  buckets = [
    {
      name = "airflow"
      expire_days = 3
      noncurrent_expire_days = 5
    },
    {
      name = "datalake"
    }
  ]
}

output "minio_service_dns" {
  value       = module.minio.minio_service_dns
  description = "The MinIO API service DNS name"
}

output "minio_service_port" {
  value       = module.minio.minio_service_port
  description = "The MinIO API service port"
}

output "minio_root_user" {
  value       = module.minio.minio_root_user
  description = "The MinIO root user"
  sensitive   = true
}

output "minio_root_password" {
  value       = module.minio.minio_root_password
  description = "The MinIO root password"
  sensitive   = true
}

# add comments v10