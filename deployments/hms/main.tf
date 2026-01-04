module "hms" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/hms?ref=v0.4.0"

  database_host     = var.db_internal_dns
  database_user     = var.db_user
  database_password = var.db_password

  s3_access_key = var.minio_root_user
  s3_secret_key = var.minio_root_password
  s3_endpoint   = "http://${var.minio_internal_dns}:9000"
}

# Add comments v1
