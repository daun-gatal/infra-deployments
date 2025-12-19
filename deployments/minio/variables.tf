variable "minio_root_password" {
  description = "MinIO root password (minimum 8 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.minio_root_password) >= 8
    error_message = "MinIO root password must be at least 8 characters long."
  }
}