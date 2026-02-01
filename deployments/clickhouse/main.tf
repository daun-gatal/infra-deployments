module "keeper" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/clickhouse/keeper?ref=v0.6.0"
}

module "server" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/clickhouse/server?ref=v0.6.0"

  admin_password      = var.ch_admin_password
  keeper_service_name = module.keeper.service_name

  depends_on = [module.keeper]
}

module "ui" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/clickhouse/ui?ref=v0.8.1"

  tailscale_expose = false
  tailscale_funnel = true
  app_name         = "chouse-ui"

  env_from_secrets = ["clickhouse-studio-secrets"]

  depends_on = [module.server]
}
