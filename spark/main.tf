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
  cluster_worker_count = 2
  worker_memory = "4Gi"
  worker_cpu = "2"
  spark_connect_executor_memory = "4Gi"
  spark_connect_max_cores = 2
}

# Add comments