terraform {
  backend "http" {}
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
}

provider "kubernetes" {
  config_path = ""
}

provider "helm" {
  kubernetes = {
    config_path = ""
  }
}


module "airbyte" {
  source = "git::https://gitlab.com/daun-gatal/terraform-modules.git//modules/airbyte?ref=main"

  values = {
    global = {
      database = {
        type = "external"
        secretName = "airbyte-config-secrets"
        host = "postgres-cluster-rw.database.svc.cluster.local"
        port = 5432
        name = "airbyte"
        userSecretKey = "DB_USER"
        passwordSecretKey = "DB_PASS"
      }
      storage = {
        secretName = "airbyte-config-secrets"
        type = "minio"
      }
    }

    fullnameOverride = "airbyte"

    postgresql = {
      enabled = false
    }

    minio = {
      enabled = false
      secretName = "airbyte-config-secrets"
    }

    server = {
      service = {
        type = "ClusterIP",
        port = 80
        annotations = {
          "tailscale.com/expose" = "true"
          "tailscale.com/hostname" = "airbyte-web-int"
        }
      }
    }
  }
}

# Add comments here if needed v2