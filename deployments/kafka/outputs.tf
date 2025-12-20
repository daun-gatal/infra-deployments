output "kafka_int_bootstrap_servers" {
  description = "Kafka bootstrap servers connection string for client applications"
  value       = module.cluster.kafka_int_bootstrap_servers
}

output "kafka_schema_registry_url" {
  description = "Schema Registry URL for client applications"
  value       = "http://${module.schema_registry_new.schema_registry_internal_dns}:${module.schema_registry_new.schema_registry_port}"
}

output "kafka_connect_url" {
  description = "Kafka Connect URL for client application"
  value       = module.connect_new.kafka_connect_endpoints
}

output "kafka_ksqldb_url" {
  description = "KSQLDB URL for client application"
  value       = "http://${module.ksqldb_new.ksqldb_internal_dns}:${module.ksqldb_new.ksqldb_port}"
}
