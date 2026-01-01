terraform {
  backend "kubernetes" {
    secret_suffix    = "dockge"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
