module "postgres_db" {
  source = "git::https://github.com/daun-gatal/terraform-modules.git//modules/postgres?ref=main"

  db_name        = "default"
  db_user        = "admin"
  db_password    = var.db_password
  storage_size   = "30Gi"
  extra_db_names = ["airflow", "metabase", "datalake", "openwebui", "openbaodb", "superset", "airbyte"]
}

# add comments v15
