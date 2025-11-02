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

module "kafka" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka?ref=main"

  kafka_replicas = 2
  storage_delete_claim = true
  offsets_topic_replication_factor = 2
  transaction_state_log_replication_factor = 2
  transaction_state_log_min_isr = 2
  default_replication_factor = 2
  min_insync_replicas = 2
  storage_type = "persistent-claim"
  storage_size = "20Gi"

  enable_kafka_ui = true
  kafka_ui_tailscale_expose = true
  kafka_ui_auth_enabled = true
  kafka_ui_auth_password = var.kafka_ui_auth_password
}

output "kafka_int_bootstrap_servers" {
  description = "Kafka bootstrap servers connection string for client applications"
  value       = module.kafka.kafka_int_bootstrap_servers
}

# add comments v7