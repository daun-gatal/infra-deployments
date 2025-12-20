output "openbao_service_dns" {
  value       = module.openbao.openbao_server_dns
  description = "The Openbao API service DNS name"
}
