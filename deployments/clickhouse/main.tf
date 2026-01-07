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
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/clickhouse/ui?ref=v0.6.0"

  clickhouse_urls = module.server.config.internal_url

  tailscale_expose = false
  tailscale_funnel = true
  app_name         = "clickhouse-ui"
  image_repository = "ghcr.io/daun-gatal/clickhouse-ui"

  depends_on = [module.server]
}
