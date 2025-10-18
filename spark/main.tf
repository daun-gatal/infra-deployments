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

module "spark" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/spark?ref=main"

  tailscale_expose = true

  spark_connect_max_cores = 5
  spark_connect_dynamic_allocation_enabled = true
  spark_connect_dynamic_allocation_max_executors = 3
  spark_connect_dynamic_allocation_shuffle_tracking_enabled = true

  extra_spark_conf = {
    "spark.hadoop.fs.s3a.access.key" = local.minio.minio_root_user.value
    "spark.hadoop.fs.s3a.endpoint" = "http://${local.minio.minio_service_dns.value}:${local.minio.minio_service_port.value}"
    "spark.hadoop.fs.s3a.path.style.access" = "true"
    "spark.hadoop.fs.s3a.secret.key" = local.minio.minio_root_password.value
    "spark.jars.ivy" = "/tmp/.ivy2.5.2"
    "spark.jars.packages" = "org.apache.hadoop:hadoop-aws:3.4.1,org.apache.iceberg:iceberg-spark-runtime-4.0_2.13:1.10.0,org.postgresql:postgresql:42.7.3"
    "spark.kubernetes.driver.pod.excludedFeatureSteps" = "org.apache.spark.deploy.k8s.features.KerberosConfDriverFeatureStep"
    "spark.kubernetes.executor.podNamePrefix" = "spark-connect-server-iceberg"
    "spark.scheduler.mode" = "FAIR"
    "spark.sql.catalog.datalake.type" = "jdbc"
    "spark.sql.catalog.datalake.catalog-impl" = "org.apache.iceberg.jdbc.JdbcCatalog"
    "spark.sql.defaultCatalog" = "datalake"
    "spark.sql.catalog.datalake" = "org.apache.iceberg.spark.SparkCatalog"
    "spark.sql.extensions" = "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
    "spark.sql.catalog.datalake.warehouse" = "s3://datalake/warehouse"
    "spark.sql.catalog.datalake.uri" = "jdbc:postgresql://${local.db.postgres_rw_dns.value}:5432/datalake"
    "spark.sql.catalog.datalake.jdbc.user" = local.db.postgres_username.value
    "spark.sql.catalog.datalake.jdbc.password" = local.db.postgres_password.value
  }
}

output "spark_connect_dns" {
  description = "The DNS name for the Spark Connect service."
  value       = module.spark.spark_connect_dns
}

output "spark_connect_port" {
  description = "The port for the Spark Connect service."
  value       = module.spark.spark_connect_port
}

# Add comments v5