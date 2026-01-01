terraform {
  backend "kubernetes" {
    secret_suffix    = "airflow"
    config_path      = "~/.kube/config"
    namespace        = "terraform"
  }
}
