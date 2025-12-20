module "minio" {
  source = "git::ssh://git@gitlab.com/daun-gatal/terraform-modules.git//modules/minio?ref=main"

  minio_root_password = var.minio_root_password
  tailscale_expose    = true
  storage_size        = "50Gi"

  buckets = [
    {
      name                   = "airflow"
      expire_days            = 3
      noncurrent_expire_days = 5
    },
    {
      name = "datalake"
    }
  ]
}

# add comments v11
