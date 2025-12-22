

locals {
  oauth_config = templatefile(
    "${path.module}/templates/oauth.tpl",
    {}
  )
}


module "superset" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/superset?ref=main"

  admin_password        = var.admin_password
  oauth_config          = local.oauth_config
  use_external_database = true

  enable_celery_worker = true
  enable_celery_beat   = true

  tailscale_expose = false
  tailscale_funnel = true
  superset_port    = 80

  bootstrap_pip_packages = ["trino"]

  enable_superset_autoscaling = false
}

# Add comments here v5
