terraform {
  backend "kubernetes" {
    secret_suffix    = "superset"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
