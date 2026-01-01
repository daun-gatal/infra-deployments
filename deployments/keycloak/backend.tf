terraform {
  backend "kubernetes" {
    secret_suffix    = "keycloak"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
