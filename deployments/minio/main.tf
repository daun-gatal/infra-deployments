module "minio" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/minio?ref=v0.2.4"

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
