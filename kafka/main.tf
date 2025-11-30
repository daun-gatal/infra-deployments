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
  kafka_cluster_name = "kafka-cluster"
}

module "kafka_cluster" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/cluster?ref=main"

  kafka_cluster_name = local.kafka_cluster_name
}

module "kafka_node_controller" {
  depends_on = [ module.kafka_cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles = ["controller"]
  kafka_node_pool_name = "controller-pool"
  kafka_cluster_name = local.kafka_cluster_name
  storage_size = "5Gi"
  storage_type = "persistent-claim"
}

module "kafka_node_broker" {
  depends_on = [ module.kafka_cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles = ["broker"]
  kafka_node_pool_name = "broker-pool"
  kafka_cluster_name = local.kafka_cluster_name
  kafka_replicas = 3
  storage_size = "5Gi"
  storage_type = "persistent-claim"
}

module "schema_registry" {
  depends_on = [ module.kafka_node_controller, module.kafka_node_broker, module.kafka_cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/schema-registry?ref=main"

  kafka_bootstrap_servers = ["PLAINTEXT://${module.kafka_cluster.kafka_int_bootstrap_servers}"]
  tailscale_expose = false
}

module "ksqldb" {
  depends_on = [ module.kafka_node_controller, module.kafka_node_broker, module.kafka_cluster, module.schema_registry ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/ksqldb?ref=main"

  kafka_bootstrap_servers = ["PLAINTEXT://${module.kafka_cluster.kafka_int_bootstrap_servers}"]
  kafka_schema_registry_url = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
  tailscale_expose = false
}

module "ui" {
  depends_on = [ module.kafka_node_controller, module.kafka_node_broker, module.kafka_cluster, module.schema_registry, module.ksqldb ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/ui?ref=main"

  kafka_bootstrap_servers = [module.kafka_cluster.kafka_int_bootstrap_servers]
  kafka_schema_registry_url = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
  kafka_ksqldb_url = "http://${module.ksqldb.ksqldb_internal_dns}:${module.ksqldb.ksqldb_port}"
  kafka_ui_version = "main"
  tailscale_expose = true
}

output "kafka_int_bootstrap_servers" {
  description = "Kafka bootstrap servers connection string for client applications"
  value       = module.kafka_cluster.kafka_int_bootstrap_servers
}

output "kafka_schema_registry_url" {
  description = "Schema Registry URL for client applications"
  value       = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
}

output "kafka_ksqldb_url" {
  description = "KSQLDB URL for client application"
  value = "http://${module.ksqldb.ksqldb_internal_dns}:${module.ksqldb.ksqldb_port}"
}
# add comments v8