terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-minio"
      project = "infra-deployments"
    }
  }
}
