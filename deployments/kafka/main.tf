locals {
  kafka_cluster_name = "kafka-cluster"
}

module "cluster" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/cluster?ref=main"

  kafka_cluster_name = local.kafka_cluster_name
}

module "node_controller" {
  depends_on = [module.cluster]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles          = ["controller"]
  kafka_node_pool_name = "controller-pool"
  kafka_cluster_name   = local.kafka_cluster_name
  storage_size         = "5Gi"
  storage_type         = "persistent-claim"
}

module "node_broker" {
  depends_on = [module.cluster]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/node?ref=main"

  kafka_roles          = ["broker"]
  kafka_node_pool_name = "broker-pool"
  kafka_cluster_name   = local.kafka_cluster_name
  kafka_replicas       = 3
  storage_size         = "5Gi"
  storage_type         = "persistent-claim"
}

module "schema_registry_new" {
  depends_on = [module.node_controller, module.node_broker, module.cluster]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/schema-registry?ref=main"

  kafka_bootstrap_servers = ["PLAINTEXT://${module.cluster.kafka_int_bootstrap_servers}"]
  tailscale_expose        = false
}

module "connect_new" {
  depends_on = [module.node_controller, module.node_broker, module.cluster, module.schema_registry_new]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/connect?ref=main"

  kafka_connect_instances = {
    connect = {
      replicas                                  = 1
      image                                     = "registry.gitlab.com/daun-gatal/image-repo/cp-kafka-connect:8.0.1"
      kafka_connect_name                        = "kafka-connect"
      kafka_bootstrap_servers                   = [module.cluster.kafka_int_bootstrap_servers]
      schema_registry_url                       = "http://${module.schema_registry_new.schema_registry_internal_dns}:${module.schema_registry_new.schema_registry_port}"
      tailscale_expose                          = false
      connect_config_storage_replication_factor = 1
      connect_offset_storage_replication_factor = 1
      connect_status_storage_replication_factor = 1
    }

    connect-replica = {
      replicas                                  = 1
      image                                     = "registry.gitlab.com/daun-gatal/image-repo/cp-kafka-connect:8.0.1"
      kafka_connect_name                        = "kafka-connect-replica"
      kafka_bootstrap_servers                   = [module.cluster.kafka_int_bootstrap_servers]
      schema_registry_url                       = "http://${module.schema_registry_new.schema_registry_internal_dns}:${module.schema_registry_new.schema_registry_port}"
      tailscale_expose                          = false
      connect_config_storage_replication_factor = 1
      connect_offset_storage_replication_factor = 1
      connect_status_storage_replication_factor = 1
    }
  }
}

module "ksqldb_new" {
  depends_on = [module.node_controller, module.node_broker, module.cluster, module.schema_registry_new]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/ksqldb?ref=main"

  kafka_bootstrap_servers   = ["PLAINTEXT://${module.cluster.kafka_int_bootstrap_servers}"]
  kafka_schema_registry_url = "http://${module.schema_registry_new.schema_registry_internal_dns}:${module.schema_registry_new.schema_registry_port}"
  tailscale_expose          = false
}

module "ui_new" {
  depends_on = [module.node_controller, module.node_broker, module.cluster, module.schema_registry_new, module.ksqldb_new, module.connect_new]
  source     = "git::https://github.com/daun-gatal/terraform-modules.git//modules/kafka/ui?ref=main"

  kafka_ui_version = "main"
  tailscale_expose = false
  tailscale_funnel = true
}

# add comments v22
