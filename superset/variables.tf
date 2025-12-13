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

variable "superset_secret_key" {
  description = "The secret key for Superset application."
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "The password for the Superset admin user."
  type        = string
  sensitive   = true
}

variable "github_client_id" {
  description = "The GitHub OAuth client ID."
  type        = string
  sensitive   = true
}

variable "github_client_secret" {
  description = "The GitHub OAuth client secret."
  type        = string
  sensitive   = true
}