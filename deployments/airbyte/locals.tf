locals {
  release_name = "airbyte"
  airbyte_port = 80

  components_with_minio_env = [
    "webapp",
    "worker",
    "workloadLauncher",
    "connectorRolloutWorker",
    "metrics",
    "airbyteBootloader",
    "temporal",
    "temporalUi",
    "cron",
  ]

  minio_extra_env = [
    {
      name = "MINIO_ENDPOINT"
      valueFrom = {
        secretKeyRef = {
          name = "airbyte-config-secrets"
          key  = "MINIO_ENDPOINT"
        }
      }
    }
  ]

  component_envs = {
    for c in local.components_with_minio_env :
    c => { extraEnv = local.minio_extra_env }
  }

  values = {
    global = {
      database = {
        type              = "external"
        secretName        = "airbyte-config-secrets"
        host              = "postgres-cluster-rw.database.svc.cluster.local"
        port              = 5432
        name              = "airbyte"
        userSecretKey     = "DB_USER"
        passwordSecretKey = "DB_PASS"
      }
      storage = {
        secretName = "airbyte-config-secrets"
        type       = "minio"
      }
    }

    postgresql = {
      enabled = false
    }

    minio = {
      enabled    = false
      secretName = "airbyte-config-secrets"
    }

    server = {
      service = {
        type = "ClusterIP"
        port = local.airbyte_port
        annotations = {
          "tailscale.com/expose"   = "false"
          "tailscale.com/hostname" = "airbyte-web-int"
        }
      }
      extraEnv = [
        {
          name = "MINIO_ENDPOINT"
          valueFrom = {
            secretKeyRef = {
              name = "airbyte-config-secrets"
              key  = "MINIO_ENDPOINT"
            }
          }
        }
      ]
    }
  }
}