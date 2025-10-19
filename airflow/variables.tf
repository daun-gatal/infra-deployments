variable "db_credentials_path" {
  description = "Path to the file containing database credentials"
  type        = string
  sensitive = true
}

variable "minio_credentials_path" {
  description = "Path to the file containing MinIO credentials"
  type        = string
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