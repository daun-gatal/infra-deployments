variable "trino_shared_secret" {
  description = "Shared secret for internal Trino communication"
  type        = string
  sensitive   = true
}

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

variable "minio_root_password" {
  description = "The root password of MINIO"
  type = string
  sensitive = true
}

variable "minio_root_user" {
  description = "The root user of MINIO"
  type = string
  sensitive = true
}

variable "minio_internal_dns" {
  description = "The internal DNS of MINIO"
  type = string
  sensitive = true
}