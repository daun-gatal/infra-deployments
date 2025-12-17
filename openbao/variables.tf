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

variable "unseal_current_key" {
  description = "Current unseal key (32 bytes, base64 encoded). Required if generate_unseal_key is false"
  type        = string
  sensitive   = true
}

variable "unseal_current_key_id" {
  description = "Identifier for the current unseal key (e.g., date-based: 2024-12-17)"
  type        = string
}

variable "unseal_previous_key" {
  description = "Previous unseal key for rotation (32 bytes, base64 encoded). Optional"
  type        = string
  sensitive   = true
}

variable "unseal_previous_key_id" {
  description = "Identifier for the previous unseal key. Required if unseal_previous_key is set"
  type        = string
}
