terraform {
  backend "kubernetes" {
    secret_suffix    = "database"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
