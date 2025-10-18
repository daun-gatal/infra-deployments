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

module "spark" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/spark?ref=main"

  tailscale_expose = true

  spark_connect_max_cores = 5
  spark_connect_dynamic_allocation_enabled = true
  spark_connect_dynamic_allocation_max_executors = 3
  spark_connect_dynamic_allocation_shuffle_tracking_enabled = true
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