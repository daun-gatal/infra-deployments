terraform {
  backend "kubernetes" {
    secret_suffix = "hms"
    config_path   = "~/.kube/config"
    namespace     = "terraform"
  }
}
