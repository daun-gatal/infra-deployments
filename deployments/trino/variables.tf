variable "trino_shared_secret" {
  description = "Shared secret for internal Trino communication"
  type        = string
  sensitive   = true
}

variable "minio_root_password" {
  description = "The root password of MINIO"
  type        = string
  sensitive   = true
}

variable "minio_root_user" {
  description = "The root user of MINIO"
  type        = string
  sensitive   = true
}

variable "minio_internal_dns" {
  description = "The internal DNS of MINIO"
  type        = string
  sensitive   = true
}
