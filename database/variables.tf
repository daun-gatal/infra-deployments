variable "db_password" {
  description = "The password for the Postgres database user."
  type        = string
  sensitive   = true
}