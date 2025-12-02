variable "db_password" {
  description = "The password for the Postgres database user."
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "The user of Postgres database."
  type        = string
  sensitive = true
}

variable "db_internal_dns" {
  description = "The internal DNS of Postgres database."
  type        = string
  sensitive = true
}