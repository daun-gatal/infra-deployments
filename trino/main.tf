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
        "iceberg.jdbc-catalog.connection-url"          = "jdbc:postgresql://${var.db_internal_dns}:5432/datalake"
        "iceberg.jdbc-catalog.connection-user"         = var.db_user
        "iceberg.jdbc-catalog.connection-password"     = var.db_password
        "iceberg.jdbc-catalog.default-warehouse-dir"   = "s3://datalake/warehouse"
        "fs.native-s3.enabled"                         = "true"
        "s3.endpoint"                                  = "http://${var.minio_internal_dns}:9000"
        "s3.region"                                    = "us-east-1"
        "s3.aws-access-key"                            = var.minio_root_user
        "s3.aws-secret-key"                            = var.minio_root_password
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
# Add comments v6