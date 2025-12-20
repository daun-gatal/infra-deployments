output "trino_acl" {
  description = "Username for the Postgres"
  value       = jsondecode(module.trino_readonly.trino_acl)
  sensitive   = true
}
