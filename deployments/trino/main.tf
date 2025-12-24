locals {
  oauth_config = templatefile(
    "${path.module}/templates/oauth.tpl",
    {}
  )

  properties = templatefile(
    "${path.module}/templates/properties.tpl",
    {}
  )
}


module "trino" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/trino?ref=main"

  trino_shared_secret   = var.trino_shared_secret
  worker_count          = 1
  coordinator_as_worker = true
  tailscale_expose      = false
  enabled_catalogs = [
    {
      name = "datalake"
      params = {
        "connector.name"                             = "iceberg"
        "iceberg.catalog.type"                       = "jdbc"
        "iceberg.jdbc-catalog.catalog-name"          = "datalake"
        "iceberg.jdbc-catalog.driver-class"          = "org.postgresql.Driver"
        "iceberg.jdbc-catalog.connection-url"        = "jdbc:postgresql://${var.db_internal_dns}:5432/datalake"
        "iceberg.jdbc-catalog.connection-user"       = var.db_user
        "iceberg.jdbc-catalog.connection-password"   = var.db_password
        "iceberg.jdbc-catalog.default-warehouse-dir" = "s3://datalake/warehouse"
        "fs.native-s3.enabled"                       = "true"
        "s3.endpoint"                                = "http://${var.minio_internal_dns}:9000"
        "s3.region"                                  = "us-east-1"
        "s3.aws-access-key"                          = var.minio_root_user
        "s3.aws-secret-key"                          = var.minio_root_password
        "s3.path-style-access"                       = "true"
      }
    }
  ]

  values = {
    accessControl = {
      type = "properties"
      properties = local.properties
    }

    envFrom = [
      {
        secretRef = {
          name = "trino-oauth-secret"
        }
      }
    ]

    server = {
      config = {
        https = {
          enabled = false
        }
      }

      coordinatorExtraConfig = local.oauth_config
    }

    ingress = {
      enabled = true
      className = "tailscale"
      annotations = {
        "tailscale.com/funnel" : "true"
      }
      hosts = [
        {
          host = "trino-ext"
          paths = [
            {
              path = "/"
              pathType = "Prefix"
            }
          ]
        }
      ]
      tls = [
        {
          secretName = ""
          hosts = [
            "trino-ext"
          ]
        }
      ]
    }
  }
}

# Add comments v9
