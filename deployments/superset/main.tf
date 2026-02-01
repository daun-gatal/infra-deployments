# locals {
#   oauth_config = templatefile(
#     "${path.module}/templates/oauth.tpl",
#     {}
#   )

#   trino_auth = templatefile(
#     "${path.module}/templates/trino_custom_auth.tpl",
#     {}
#   )
# }


# module "superset" {
#   source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/superset?ref=v0.2.4"

#   admin_password        = var.admin_password
#   oauth_config          = local.oauth_config
#   use_external_database = true

#   enable_celery_worker = true
#   enable_celery_beat   = true

#   tailscale_expose = false
#   tailscale_funnel = true
#   superset_port    = 80

#   bootstrap_pip_packages = ["trino", "clickhouse-connect"]

#   enable_superset_autoscaling = false

#   values = {
#     extraConfigs = {
#       "trino_custom_auth.py" = local.trino_auth
#     }

#     extraEnv = {
#       PYTHONPATH = "/app/pythonpath:/app/configs"
#     }
#   }
# }

# # Add comments here v14
