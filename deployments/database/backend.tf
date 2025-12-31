terraform {
  cloud {
    organization = "daun-gatal"

    workspaces {
      name = "infra-deployments-database"
      project = "infra-deployments"
    }
  }
}
