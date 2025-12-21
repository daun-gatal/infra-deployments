variable "db_internal_dns" {
  description = "The internal DNS of Postgres database."
  type        = string
  sensitive   = true
}
