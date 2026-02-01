# locals {
#   oauth_config = templatefile(
#     "${path.module}/templates/oauth.tpl",
#     {}
#   )

#   properties = templatefile(
#     "${path.module}/templates/properties.tpl",
#     {}
#   )
# }


# module "trino" {
#   source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/trino?ref=v0.2.4"

#   trino_shared_secret   = var.trino_shared_secret
#   worker_count          = 1
#   coordinator_as_worker = false
#   enabled_catalogs = [
#     {
#       name = "datalake"
#       params = {
#         "connector.name"                     = "iceberg"
#         "iceberg.catalog.type"               = "hive_metastore"
#         "hive.metastore.uri"                 = "thrift://hms-metastore.hms.svc.cluster.local:9083"
#         "hive.metastore.thrift.catalog-name" = "hive"
#         "fs.native-s3.enabled"               = "true"
#         "s3.endpoint"                        = "http://${var.minio_internal_dns}:9000"
#         "s3.region"                          = "us-east-1"
#         "s3.aws-access-key"                  = var.minio_root_user
#         "s3.aws-secret-key"                  = var.minio_root_password
#         "s3.path-style-access"               = "true"
#       }
#     },
#     {
#       name = "delta"
#       params = {
#         "connector.name"          = "delta_lake"
#         "hive.metastore.uri"      = "thrift://hms-metastore.hms.svc.cluster.local:9083"
#         "delta.hive-catalog-name" = "hive"
#         "fs.native-s3.enabled"    = "true"
#         "s3.endpoint"             = "http://${var.minio_internal_dns}:9000"
#         "s3.region"               = "us-east-1"
#         "s3.aws-access-key"       = var.minio_root_user
#         "s3.aws-secret-key"       = var.minio_root_password
#         "s3.path-style-access"    = "true"
#       }
#     }
#   ]

#   values = {
#     accessControl = {
#       type       = "properties"
#       properties = local.properties
#     }

#     envFrom = [
#       {
#         secretRef = {
#           name = "trino-oauth-secret"
#         }
#       }
#     ]

#     server = {
#       config = {
#         https = {
#           enabled = false
#         }
#       }

#       coordinatorExtraConfig = local.oauth_config
#     }

#     ingress = {
#       enabled   = true
#       className = "tailscale"
#       annotations = {
#         "tailscale.com/funnel" : "true"
#       }
#       hosts = [
#         {
#           host = "trino-ext"
#           paths = [
#             {
#               path     = "/"
#               pathType = "Prefix"
#             }
#           ]
#         }
#       ]
#       tls = [
#         {
#           secretName = ""
#           hosts = [
#             "trino-ext"
#           ]
#         }
#       ]
#     }
#   }
# }

# # Add comments v10
