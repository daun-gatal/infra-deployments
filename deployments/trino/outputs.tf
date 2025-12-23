output "trino_acl" {
  description = "Username for the Postgres"
  value       = jsondecode(module.trino.trino_acl)
  sensitive   = true
}
