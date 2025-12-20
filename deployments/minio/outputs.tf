output "minio_service_dns" {
  value       = module.minio.minio_service_dns
  description = "The MinIO API service DNS name"
}

output "minio_service_port" {
  value       = module.minio.minio_service_port
  description = "The MinIO API service port"
}

output "minio_root_user" {
  value       = module.minio.minio_root_user
  description = "The MinIO root user"
  sensitive   = true
}

output "minio_root_password" {
  value       = module.minio.minio_root_password
  description = "The MinIO root password"
  sensitive   = true
}
