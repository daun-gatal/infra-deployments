terraform {
  backend "kubernetes" {
    secret_suffix    = "trino"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
