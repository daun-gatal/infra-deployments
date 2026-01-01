terraform {
  backend "kubernetes" {
    secret_suffix    = "kafka"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
