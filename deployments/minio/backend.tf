terraform {
  backend "kubernetes" {
    secret_suffix    = "minio"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
