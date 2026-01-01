terraform {
  backend "kubernetes" {
    secret_suffix    = "openbao"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
