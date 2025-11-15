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

module "trino_readonly" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/trino?ref=main"

  trino_shared_secret   = var.trino_shared_secret
  worker_count          = 1
  coordinator_as_worker = true
  tailscale_expose      = true
  enabled_catalogs = [
    {
      name = "datalake"
      params = {
        "connector.name"                               = "iceberg"
        "iceberg.catalog.type"                         = "jdbc"
        "iceberg.jdbc-catalog.catalog-name"            = "datalake"
        "iceberg.jdbc-catalog.driver-class"            = "org.postgresql.Driver"
        "iceberg.jdbc-catalog.connection-url"          = "jdbc:postgresql://${local.db.postgres_rw_dns.value}:5432/datalake"
        "iceberg.jdbc-catalog.connection-user"         = local.db.postgres_username.value
        "iceberg.jdbc-catalog.connection-password"     = local.db.postgres_password.value
        "iceberg.jdbc-catalog.default-warehouse-dir"   = "s3://datalake/warehouse"
        "fs.native-s3.enabled"                         = "true"
        "s3.endpoint"                                  = "http://${local.minio.minio_service_dns.value}:${local.minio.minio_service_port.value}"
        "s3.region"                                    = "us-east-1"
        "s3.aws-access-key"                            = local.minio.minio_root_user.value
        "s3.aws-secret-key"                            = local.minio.minio_root_password.value
        "s3.path-style-access"                         = "true"
      }
    }
  ]
}

output "trino_acl" {
  description = "Username for the Postgres"
  value       = jsondecode(module.trino_readonly.trino_acl)
  sensitive   = true
}
# Add comments v5