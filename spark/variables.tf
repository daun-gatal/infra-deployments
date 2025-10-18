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