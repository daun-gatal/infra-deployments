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
      secretName = "airbyte-config-secrets"
      auth = {
        instanceAdmin = {
          firstName = "Airbyte"
          lastName = "Admin"
          emailSecretKey = "admin-email"
          passwordSecretKey = "admin-password"
        }
      }
      database = {
        type = "external"
        secretName = "airbyte-config-secrets"
        host = "postgres-cluster-rw.database.svc.cluster.local"
        port = 5432
        name = "airbyte"
        userSecretKey = "database-user"
        passwordSecretKey = "database-password"
      }
    }

    fullnameOverride = "airbyte"
    postgresql_enabled = false

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

# Add comments here if needed v1