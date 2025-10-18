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

module "nessie" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/nessie?ref=main"

  nessie_jdbc_username        = local.db.postgres_username.value
  nessie_jdbc_password        = local.db.postgres_password.value
  nessie_jdbc_url             = local.db.postgres_rw_dns.value
  nessie_jdbc_port            = 5432
  nessie_database_name        = "nessie"
  nessie_s3_bucket            = "datalake"
  nessie_s3_endpoint          = "http://${local.minio.minio_service_dns.value}:${local.minio.minio_service_port.value}"
  nessie_s3_access_key_name   = local.minio.minio_root_user.value
  nessie_s3_access_key_secret = local.minio.minio_root_password.value
  tailscale_expose            = true
}

output "nessie_service_dns" {
  value       = module.nessie.nessie_service_dns
  description = "The Nessie service DNS name"
}

output "nessie_service_port" {
  value       = module.nessie.nessie_service_port
  description = "The Nessie service port"
}

output "nessie_default_warehouse" {
  value       = module.nessie.nessie_default_warehouse
  description = "The default warehouse location in S3 for Nessie"
}

output "nessie_s3_endpoint" {
  value       = module.nessie.nessie_s3_endpoint
  description = "The S3 endpoint for Nessie"
  sensitive = true
}

output "nessie_s3_region" {
  value       = module.nessie.nessie_s3_region
  description = "The S3 region for Nessie"
}