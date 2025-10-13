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

  enable_kafka_ui = true
  kafka_ui_tailscale_expose = true
  kafka_ui_auth_enabled = true
  kafka_ui_auth_password = var.kafka_ui_auth_password
}