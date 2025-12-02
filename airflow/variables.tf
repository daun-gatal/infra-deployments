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

variable "airflow_fernet_key" {
  description = "Fernet key for Airflow"
  type        = string
  sensitive = true
}

variable "airflow_api_secret_key" {
  description = "API secret key for Airflow"
  type        = string
  sensitive = true
}

variable "airflow_password" {
  description = "Default password for Airflow"
  type        = string
  sensitive = true
}

variable "git_username" {
  description = "Git username for accessing DAGs repository"
  type        = string
}

variable "git_password" {
  description = "Git password or PAT for accessing DAGs repository"
  type        = string
  sensitive = true
}