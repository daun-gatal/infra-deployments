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
  kafka_cluster_name = "kafka-cluster"
}

module "cluster" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/cluster?ref=main"

  kafka_cluster_name = local.kafka_cluster_name
}

module "node_controller" {
  depends_on = [ module.cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles = ["controller"]
  kafka_node_pool_name = "controller-pool"
  kafka_cluster_name = local.kafka_cluster_name
  storage_size = "5Gi"
  storage_type = "persistent-claim"
}

module "node_broker" {
  depends_on = [ module.cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles = ["broker"]
  kafka_node_pool_name = "broker-pool"
  kafka_cluster_name = local.kafka_cluster_name
  kafka_replicas = 3
  storage_size = "5Gi"
  storage_type = "persistent-claim"
}

module "schema_registry" {
  depends_on = [ module.node_controller, module.node_broker, module.cluster ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/schema-registry?ref=main"

  kafka_bootstrap_servers = ["PLAINTEXT://${module.kafka_cluster.kafka_int_bootstrap_servers}"]
  tailscale_expose = false
}

module "connect" {
  depends_on = [ module.node_controller, module.node_broker, module.cluster, module.schema_registry ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/connect?ref=main"

  tailscale_expose = false
  kafka_connect_image = "registry.gitlab.com/daun-gatal/image-repo/cp-kafka-connect:8.0.1"
  kafka_bootstrap_servers = [module.kafka_cluster.kafka_int_bootstrap_servers]
  schema_registry_url = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
}

module "ksqldb" {
  depends_on = [ module.node_controller, module.node_broker, module.cluster, module.schema_registry ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/ksqldb?ref=main"

  kafka_bootstrap_servers = ["PLAINTEXT://${module.kafka_cluster.kafka_int_bootstrap_servers}"]
  kafka_schema_registry_url = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
  tailscale_expose = false
}

module "ui" {
  depends_on = [ module.node_controller, module.node_broker, module.cluster, module.schema_registry, module.ksqldb, module.connect ]
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/kafka/ui?ref=main"
  
  kafka_ui_version = "main"
  tailscale_expose = true
}

output "kafka_int_bootstrap_servers" {
  description = "Kafka bootstrap servers connection string for client applications"
  value       = module.cluster.kafka_int_bootstrap_servers
}

output "kafka_schema_registry_url" {
  description = "Schema Registry URL for client applications"
  value       = "http://${module.schema_registry.schema_registry_internal_dns}:${module.schema_registry.schema_registry_port}"
}

output "kafka_connect_url" {
  description = "Kafka Connect URL for client application"
  value = "http://${module.connect.kafka_connect_internal_dns}:${module.connect.kafka_connect_port}"
}

output "kafka_ksqldb_url" {
  description = "KSQLDB URL for client application"
  value = "http://${module.ksqldb.ksqldb_internal_dns}:${module.ksqldb.ksqldb_port}"
}
# add comments v14