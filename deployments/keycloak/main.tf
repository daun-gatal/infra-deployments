module "keycloak" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/keycloak?ref=main"

  db_host = var.db_internal_dns

  db_username_secret = {
    name = "keycloak-db-secret"
    key  = "username"
  }

  db_password_secret = {
    name = "keycloak-db-secret"
    key  = "password"
  }

  tailscale_funnel = true
}

# test