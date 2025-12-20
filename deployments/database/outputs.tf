output "postgres_rw_dns" {
  description = "Name of the Postgres service"
  value       = module.postgres_db.postgres_rw_dns
}

output "postgres_password" {
  description = "Password for the Postgres"
  value       = module.postgres_db.postgres_password
  sensitive   = true
}

output "postgres_username" {
  description = "Username for the Postgres"
  value       = module.postgres_db.postgres_username
  sensitive   = true
}
