terraform {
  backend "kubernetes" {
    secret_suffix = "clickhouse"
    config_path   = "~/.kube/config"
    namespace     = "terraform"
  }
}
